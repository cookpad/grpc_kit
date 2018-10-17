# frozen_string_literal: true

module GrpcKit
  module Streams
    class Stream
      include GrpcKit::Rpcs::Packable

      def initialize(protobuf:, session:, stream:)
        @protobuf = protobuf
        @session = session
        @stream = stream
      end

      def send(last: false)
        req = @protobuf.encode(data)
        @stream.write_send_data(pack(req), last: last)
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
end
