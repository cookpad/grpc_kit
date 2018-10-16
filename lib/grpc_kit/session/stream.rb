# frozen_string_literal: false

require 'forwardable'
require 'grpc_kit/session/buffer'
require 'grpc_kit/session/headers'

module GrpcKit
  module Session
    class Stream
      extend Forwardable

      delegate end_write: :@pending_send_data

      attr_reader :headers, :stream_id, :session
      attr_accessor :local_end_stream, :remote_end_stream, :inflight, :end_stream

      def initialize(stream_id:, session:, end_read_stream: false)
        @stream_id = stream_id
        @end_read_stream = end_read_stream
        @session = session
        @end_stream = false
        @headers = GrpcKit::Session::Headers.new
        @pending_send_data = GrpcKit::Session::Buffer.new

        @read_data = Queue.new

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

      def process_header_feild(key, val)
        HeaderProcessor.call(key, val, @headers)
      end

      def recv(data)
        @read_data.push(data)
      end

      def read_recv_data
        loop do
          data =
            if has_read_data?
              @read_data.pop
            else
              nil
            end

          unless data
            if end_read?
              return nil
            end

            session.run_once
            redo
          end

          return data
        end
      end

      def consume_read_data
        @session.run_once(@stream_id) # XXX

        if has_read_data?
          @read_data.pop
        else
          nil
        end
      end

      def has_read_data?
        !@read_data.empty?
      end

      def end_write?
        @local_end_stream || @pending_send_data.end_write?
      end

      def end_read
        @end_read_stream = true
      end

      def end_read?
        @remote_end_stream
      end

      def write(data)
        @pending_send_data.write(data)
      end

      def consume_write_data(len)
        @pending_send_data.read(len)
      end

      def end_stream
        @end_read_stream = true
        end_write
      end

      def end_stream?
        @end_read_stream && end_write?
      end

      def add_header(name, value)
        @headers.add(name, value)
      end
    end
  end
end
