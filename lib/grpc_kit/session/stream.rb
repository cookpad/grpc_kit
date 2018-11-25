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

      delegate %i[end_write end_write?] => :@pending_send_data
      delegate %i[end_read end_read?] => :@pending_recv_data
      delegate %i[close close_remote close_local close? close_remote? close_local?] => :@status

      attr_reader :headers, :pending_send_data, :pending_recv_data, :trailer_data, :status
      attr_accessor :inflight, :stream_id

      # @param stream_id [Integer]
      # @param send_data [GrpcKit::Session::SendBuffer]
      # @param recv_data [GrpcKit::Session::RecvBuffer]
      def initialize(stream_id:, send_data: nil, recv_data: nil)
        @stream_id = stream_id
        @end_read_stream = false
        @headers = GrpcKit::Session::Headers.new
        @pending_send_data = send_data || GrpcKit::Session::SendBuffer.new
        @pending_recv_data = recv_data || GrpcKit::Session::RecvBuffer.new

        @inflight = false
        @trailer_data = {}
        @status = GrpcKit::Session::StreamStatus.new
        @draining = false
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
      # @return [void]
      def read_recv_data(last: false)
        @pending_recv_data.read(last: last)
      end

      # @param name [String]
      # @param value [String]
      # @return [void]
      def add_header(name, value)
        @headers.add(name, value)
      end
    end
  end
end
