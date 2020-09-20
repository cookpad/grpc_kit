# frozen_string_literal: true

require 'grpc_kit/transport/packable'

module GrpcKit
  module Transport
    class ServerTransport
      include GrpcKit::Transport::Packable

      # @param session [GrpcKit::ControlQueue]
      # @param stream [GrpcKit::Session::Stream]
      def initialize(control_queue, stream)
        @control_queue = control_queue
        @stream = stream
      end

      # @param headers [Hash<String, String>]
      # @return [void]
      def start_response(headers)
        @control_queue.submit_response(@stream.stream_id, headers)
        send_data
      end

      # @param headers [Hash<String, String>]
      # @return [void]
      def submit_headers(headers)
        @control_queue.submit_headers(@stream.stream_id, headers)
      end

      # @param buf [String]
      # @param last [Boolean]
      # @return [void]
      def write_data(buf, last: false)
        @stream.write_send_data(pack(buf), last: last)
        send_data
      end

      # @param last [Boolean]
      # @return [nil,Array<Boolean,Integer,String>] nil when closed, tuple of Length-Prefixed-Message
      def read_data(last: false)
        data_in_buffer = unpack(nil)
        return data_in_buffer if data_in_buffer
        loop do
          data = recv_data(last: last)
          return unpack(nil) unless data
          message = unpack(data)
          return message if message
        end
      end

      # @param trailer [Hash<String, String>]
      # @return [void]
      def write_trailers(trailer)
        @stream.write_trailers_data(trailer)
        send_data
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
        @stream.read_recv_data(last: last, blocking: true)
      end

      def send_data
        @control_queue.resume_data(@stream.stream_id)
      end
    end
  end
end
