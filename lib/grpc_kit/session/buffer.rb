# frozen_string_literal: true

module GrpcKit
  module Session
    class Buffer
      attr_accessor :finish

      def initialize(buffer: nil)
        @buffer = buffer
        @end_read = false
        @end_write = false
        @finish = false
      end

      def write(data, last: false)
        return 0 if data.empty?

        end_write if last

        if @buffer
          @buffer << data
        else
          @buffer = data.dup
        end

        data.bytesize
      end

      def read(len = nil, last: false)
        if @buffer.nil? || @buffer.empty?
          return ''
        end

        end_read if last

        # TODO: more efficient code
        if len
          @buffer.slice!(0...len)
        else
          @buffer.slice!(0..-1)
        end
      end

      def end_read?
        @end_read
      end

      def end_write?
        @end_write
      end

      def end_read
        @end_read = true
      end

      def end_write
        @end_write = true
      end
    end
  end
end
