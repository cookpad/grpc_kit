# frozen_string_literal: true

module GrpcKit
  module Transport
    class SendBuffer
      def initialize
        @buffer = nil
        @end_write = false
        @deferred_read = false
      end

      def write(data, last: false)
        end_write if last

        if @buffer
          @buffer << data
        else
          @buffer = data
        end
      end

      def need_resume?
        @deferred_read
      end

      def end_write
        @end_write = true
      end

      def end_write?
        @end_write
      end

      def read(size)
        if @buffer.nil?
          @deferred_read = true
          return DS9::ERR_DEFERRED
        end

        data = @buffer.slice!(0, size)
        if !data.empty?
          @deferred_read = false
          data
        elsif end_write?
          @deferred_read = false
          nil # EOF
        else
          @deferred_read = true
          DS9::ERR_DEFERRED
        end
      end
    end
  end
end
