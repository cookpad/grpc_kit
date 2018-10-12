# frozen_string_literal: false

require 'grpc_kit/session/header'

module GrpcKit
  module Session
    class Stream
      attr_reader :headers, :header_builder, :stream_id, :session
      attr_accessor :data, :handling

      def initialize(stream_id:, session:, end_read_stream: false, end_write_stream: false)
        @stream_id = stream_id
        @end_read_stream = end_read_stream
        @end_write_stream = end_write_stream
        @session = session
        @end_stream = false
        @headers = Header.new({}) # Set metadata {}

        @read_data = Queue.new
        @write_data = ''
        @handling = false
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

      def end_write
        @end_write_stream = true
      end

      def end_write?
        @end_write_stream
      end

      def end_read
        @end_read_stream = true
      end

      def end_read?
        @end_read_stream
      end

      def write(data)
        @write_data << data
      end

      def consume_write_data(len)
        @write_data.slice!(0, len)
      end

      def end_stream
        @end_read_stream = true
        @end_write_stream = true
      end

      def end_stream?
        @end_read_stream && @end_write_stream
      end
    end
  end
end
