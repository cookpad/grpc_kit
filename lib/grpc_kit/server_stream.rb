# frozen_string_literal: true

require 'grpc_kit/rpcs/packable'

module GrpcKit
  class ServerStream
    include GrpcKit::Rpcs::Packable

    def initialize(stream:, protobuf:)
      @stream = stream
      @protobuf = protobuf
      @sent_first_msg = false
    end

    def recv
      req = nil

      loop do
        data = @stream.consume_read_data

        if data.nil?
          if @stream.end_read?
            break
          else
            next
          end
        end

        compressed, size, buf = unpack(data)

        unless size == buf.size
          raise "inconsistent data: #{buf}"
        end

        if compressed
          raise 'compress option is unsupported'
        end

        req = @protobuf.decode(buf)
        if req
          return req
        end
      end

      raise StopIteration
    end

    def send_msg(data)
      resp = @protobuf.encode(data)
      @stream.write(pack(resp))
      return if @sent_first_msg

      @stream.submit_response(status: 200)
      @sent_first_msg = true
    end
  end
end
