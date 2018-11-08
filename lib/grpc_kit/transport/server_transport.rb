# frozen_string_literal: true

require 'grpc_kit/transport/packable'

module GrpcKit
  module Transport
    class ServerTransport
      include GrpcKit::Transport::Packable

      # @params session [GrpcKit::Session::ServerSession]
      # @params stream [GrpcKit::Session::Stream]
      def initialize(session, stream)
        @session = session
        @stream = stream
      end

      def each
        loop do
          data = recv
          return if data.nil?

          yield(data)
        end
      end

      def start_response(headers)
        @session.submit_response(@stream.stream_id, headers)
        send_data
      end

      def submit_headers(headers)
        @session.submit_headers(@stream.stream_id, headers)
      end

      def write_data(buf, last: false)
        @stream.write_send_data(pack(buf), last: last)
        send_data
      end

      def read_data(last: false)
        unpack(read(last: last))
      end

      def write_trailers(trailer)
        @stream.write_trailers_data(trailer)
        send_data
      end

      def end_write
        @stream.end_write
      end

      def recv_headers
        @stream.headers
      end

      private

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
