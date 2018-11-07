# frozen_string_literal: true

module GrpcKit
  module Transport
    class SendBuffer
      def initialize
        @buffer = nil
        @end_write = false
      end

      def write(data, last: false)
        end_write if last

        if @buffer
          @buffer << data
        else
          @buffer = data
        end
      end

      def end_write
        @end_write = true
      end

      def end_write?
        @end_write
      end

      def read(size)
        if @buffer.nil?
          return DS9::ERR_DEFERRED
        end

        data = @buffer.slice!(0, size)
        if !data.empty?
          data
        elsif end_write?
          nil # EOF
        else
          DS9::ERR_DEFERRED
        end
      end
    end
  end
end
