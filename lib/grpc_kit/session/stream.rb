# frozen_string_literal: false

require 'forwardable'
require 'grpc_kit/session/buffer'
require 'grpc_kit/session/headers'

module GrpcKit
  module Session
    class Stream
      extend Forwardable

      delegate end_write: :@pending_send_data
      delegate end_read: :@pending_recv_data

      attr_reader :headers, :stream_id, :session, :pending_send_data, :pending_recv_data
      attr_accessor :local_end_stream, :remote_end_stream, :inflight

      def initialize(stream_id:, session:)
        @stream_id = stream_id
        @end_read_stream = false
        @session = session
        @headers = GrpcKit::Session::Headers.new
        @pending_send_data = GrpcKit::Session::Buffer.new
        @pending_recv_data = GrpcKit::Session::Buffer.new

        @local_end_stream = false
        @remote_end_stream = false
        @inflight = false
      end

      def submit_response(status:)
        @session.submit_response(
          @stream_id,
          ':status' => status.to_s,
          'content-type' => 'application/grpc',
          'accept-encoding' => 'identity',
        )
      end

      def write_send_data(data, last: false)
        @pending_send_data.write(data, last: last)
      end

      def read_recv_data(last: false)
        loop do
          data = @pending_recv_data.read(last: last)
          if data.empty?
            if end_read?
              return nil
            end

            session.run_once
            redo
          end

          return data
        end
      end

      def end_write?
        @local_end_stream || @pending_send_data.end_write?
      end

      def end_read?
        @remote_end_stream || @pending_recv_data.end_read?
      end

      def end_stream?
        end_read? && end_write?
      end

      def end_stream
        end_read
        end_write
      end

      def add_header(name, value)
        @headers.add(name, value)
      end
    end
  end
end
