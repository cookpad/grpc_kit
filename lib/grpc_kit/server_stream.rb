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

    def recv(last: false)
      data = unpack(@stream.read_recv_data(last: last))
      unless data
        raise StopIteration
      end

      compressed, size, buf = *data

      unless size == buf.size
        raise "inconsistent data: #{buf}"
      end

      if compressed
        raise 'compress option is unsupported'
      end

      @protobuf.decode(buf)
    end

    def send_msg(data, last: false)
      resp = @protobuf.encode(data)
      @stream.write_send_data(pack(resp), last: last)
      return if @sent_first_msg

      @stream.submit_response(status: 200)
      @sent_first_msg = true
    end
  end
end
