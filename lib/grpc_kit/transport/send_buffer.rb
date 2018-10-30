# frozen_string_literal: true

module GrpcKit
  module Transport
    class SendBuffer
      def initialize
        @buffer = nil
        @pos = 0
        @end_write = false
      end

      def write(data, last: false)
        end_write if last

        if @buffer
          @buffer << data
        else
          @buffer = data
        end

        data.size
      end

      def end_write
        @end_write = true
      end

      def end_write?
        @end_write
      end

      def read(size)
        if @buffer.nil?
          return false
        end

        data = @buffer.slice!(0, size)
        if !data.empty?
          data
        elsif end_write?
          nil # EOF
        else
          false # deferred
        end
      end
    end
  end
end
