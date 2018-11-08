# frozen_string_literal: true

require 'grpc_kit/transport/packable'

module GrpcKit
  module Transport
    class ClientTransport
      include GrpcKit::Transport::Packable

      # @params session [GrpcKit::Session::ClientSession]
      def initialize(session)
        @session = session
        @stream = nil # set later
      end

      def start_request(data, header, last: false)
        @stream = @session.send_request(header)
        write_data(data, last: last)
      end

      def close_and_flush
        @stream.end_write
        send_data

        @session.start(@stream.stream_id)
        @stream.end_read
        @deferred = false
      end

      def each
        loop do
          data = recv
          return if data.nil?

          yield(data)
        end
      end

      def write_data(buf, last: false)
        write(@stream.pending_send_data, pack(buf), last: last)
        send_data
      end

      def read_data(last: false)
        unpack(read(last: last))
      end

      def recv_headers
        wait_close
        @stream.headers
      end

      private

      def wait_close
        # XXX: wait until half close (remote) to get grpc-status
        until @stream.close_remote?
          @session.run_once
        end
      end

      def write(stream, buf, last: false)
        stream.write(buf, last: last)
      end

      def read(last: false)
        loop do
          data = @stream.read_recv_data(last: last)
          return data unless data.empty?

          if @stream.close_remote?
            # it do not receive data which we need, it may receive invalid grpc-status
            unless @stream.end_read?
              return nil
            end

            return nil
          end

          @session.run_once
        end
      end

      def send_data
        if @stream.pending_send_data.need_resume?
          @session.resume_data(@stream.stream_id)
        end

        @session.run_once
      end
    end
  end
end
