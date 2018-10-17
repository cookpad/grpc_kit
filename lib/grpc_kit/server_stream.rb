# frozen_string_literal: true

require 'grpc_kit/rpcs/packable'

module GrpcKit
  class ServerStream
    include GrpcKit::Rpcs::Packable

    def initialize(stream:, protobuf:, session:)
      @stream = stream
      @protobuf = protobuf
      @session = session
      @sent_first_msg = false
    end

    def recv(last: false)
      data = unpack(read(last: last))
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

      @session.submit_response(
        @stream.stream_id,
        ':status' => '200',
        'content-type' => 'application/grpc',
        'accept-encoding' => 'identity',
      )
      @sent_first_msg = true
    end

    private

    def read(last: false)
      loop do
        data = @stream.read_recv_data(last: last)
        if data.empty?
          if @stream.end_read?
            return nil
          end

          @session.run_once
          redo
        end

        return data
      end
    end
  end
end
