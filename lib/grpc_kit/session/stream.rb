# frozen_string_literal: true

require 'forwardable'
require 'grpc_kit/session/headers'
require 'grpc_kit/session/stream_status'
require 'grpc_kit/session/recv_buffer'
require 'grpc_kit/session/send_buffer'

module GrpcKit
  module Session
    class Stream
      extend Forwardable

      delegate %i[end_write?] => :@pending_send_data
      delegate %i[end_read?] => :@pending_recv_data

      attr_reader :headers, :pending_send_data, :pending_recv_data, :trailer_data, :status
      attr_accessor :inflight, :stream_id

      # @param stream_id [Integer]
      def initialize(stream_id:)
        @stream_id = stream_id
        @end_read_stream = false
        @headers = GrpcKit::Session::Headers.new
        @pending_send_data = GrpcKit::Session::SendBuffer.new
        @pending_recv_data = GrpcKit::Session::RecvBuffer.new

        @inflight = false
        @trailer_data = {}
        @status = GrpcKit::Session::StreamStatus.new
        @draining = false
      end

      def end_write
        @pending_send_data.end_write
      end

      def end_read
        @pending_recv_data.end_read
      end

      # @return [void]
      def drain
        @draining = true
      end

      # @param tarilers [Hash<String,String>]
      # @return [void]
      def write_trailers_data(tarilers)
        @trailer_data = tarilers
      end

      # @param data [String]
      # @param last [Boolean]
      # @return [void]
      def write_send_data(data, last: false)
        @pending_send_data.write(data, last: last)
      end

      # @param last [Boolean]
      # @param blocking [Boolean]
      # @return [void]
      def read_recv_data(last: false, blocking:)
        @pending_recv_data.read(last: last, blocking: blocking)
      end

      # @param name [String]
      # @param value [String]
      # @return [void]
      def add_header(name, value)
        @headers.add(name, value)
      end

      delegate %i[close_local close? close_remote? close_local?] => :@status

      def close
        status.close
        pending_recv_data.close
      end

      def close_remote
        status.close_remote
        pending_recv_data.close
      end
    end
  end
end
