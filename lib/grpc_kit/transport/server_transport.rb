# frozen_string_literal: true

require 'grpc_kit/transport/packable'

module GrpcKit
  module Transport
    class ServerTransport
      include GrpcKit::Transport::Packable

      # @param session [GrpcKit::Session::ServerSession]
      # @param stream [GrpcKit::Session::Stream]
      def initialize(session, stream)
        @session = session
        @stream = stream
      end

      # @param headers [Hash<String, String>]
      # @return [void]
      def start_response(headers)
        @session.submit_response(@stream.stream_id, headers)
        send_data
      end

      # @param headers [Hash<String, String>]
      # @return [void]
      def submit_headers(headers)
        @session.submit_headers(@stream.stream_id, headers)
      end

      # @param buf [String]
      # @param last [Boolean]
      # @return [void]
      def write_data(buf, last: false)
        @stream.write_send_data(pack(buf), last: last)
        send_data(last: last)
      end

      # @param last [Boolean]
      # @return [nil,String]
      def read_data(last: false)
        unpack(recv_data(last: last))
      end

      # @param trailer [Hash<String, String>]
      # @return [void]
      def write_trailers(trailer)
        @stream.write_trailers_data(trailer)
        send_data(last: true)
      end

      # @return [void]
      def end_write
        @stream.end_write
      end

      # @return [Hash<String,String>]
      def recv_headers
        @stream.headers
      end

      private

      def recv_data(last: false)
        loop do
          data = @stream.read_recv_data(last: last)
          return data unless data.nil?

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

      def send_data(last: false)
        if @stream.pending_send_data.need_resume?
          @session.resume_data(@stream.stream_id)
        end

        unless last
          @session.run_once
        end
      end
    end
  end
end
