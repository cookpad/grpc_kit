# frozen_string_literal: false

require 'forwardable'
require 'grpc_kit/session/buffer'
require 'grpc_kit/session/headers'
require 'grpc_kit/session/stream_status'
require 'grpc_kit/session/recv_buffer'

module GrpcKit
  module Session
    class Stream
      extend Forwardable

      delegate %i[end_write end_write?] => :@pending_send_data
      delegate %i[end_read end_read?] => :@pending_recv_data
      delegate %i[close close_remote close_local close? close_remote? close_local?] => :@status

      attr_reader :headers, :pending_send_data, :pending_recv_data, :trailer_data, :status
      attr_accessor :inflight, :stream_id

      def initialize(stream_id:, send_data: nil, recv_data: nil)
        @stream_id = stream_id
        @end_read_stream = false
        @headers = GrpcKit::Session::Headers.new
        @pending_send_data = send_data || GrpcKit::Session::Buffer.new
        @pending_recv_data = recv_data || GrpcKit::Session::RecvBuffer.new

        @inflight = false
        @trailer_data = {}
        @status = GrpcKit::Session::StreamStatus.new
        @draining = false
      end

      def drain
        @draining = true
      end

      def write_trailers_data(tariler)
        @trailer_data = tariler
      end

      def write_send_data(data, last: false)
        @pending_send_data.write(data, last: last)
      end

      def read_recv_data(last: false)
        @pending_recv_data.read(last: last)
      end

      def add_header(name, value)
        @headers.add(name, value)
      end
    end
  end
end
