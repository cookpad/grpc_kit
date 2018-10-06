# frozen_string_literal: true

require 'ds9'

module GrpcKit
  module Session
    class Stream
      attr_reader :headers
      attr_accessor :data

      def initialize(stream_id:, end_read_stream: false, end_write_stream: false)
        @stream_id = stream_id
        @end_read_stream = end_read_stream
        @end_write_stream = end_write_stream
        @headers = {}

        @data = ''
        @write_data = StringIO.new
      end

      def exist_data?
        !@data.empty?
      end

      def recv(data)
        @data = data            # XXX
      end

      # TODO: name
      def send(data)
        @write_data = data
        # @write_data.write(data)
      end

      # TODO: name
      def read(len)
        # @write_data.rewind
        @write_data.read(len)
      end

      def read_stream_end?
        @end_read_stream
      end

      def write_stream_end?
        @end_write_stream
      end
    end
  end
end
