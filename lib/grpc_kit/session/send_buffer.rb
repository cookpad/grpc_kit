# frozen_string_literal: true

module GrpcKit
  module Session
    class SendBuffer
      def initialize
        @buffer = ''.b
        @end_write = false
        @deferred_read = false
      end

      # @param data [String]
      # @param last [Boolean]
      # @return [void]
      def write(data, last: false)
        end_write if last
        @buffer << data
      end

      # @return [Boolean]
      def need_resume?
        @deferred_read
      end

      # @return [void]
      def end_write
        @end_write = true
      end

      # @return [Boolean]
      def end_write?
        @end_write
      end

      # @param size [Integer,nil]
      # @return [nil,DS9::ERR_DEFERRED,String]
      def read(size = nil)
        if @buffer.empty?
          if end_write?
            @deferred_read = false
            return nil # EOF
          end

          @deferred_read = true
          return DS9::ERR_DEFERRED
        end

        if size.nil? || @buffer.bytesize < size
          buf = @buffer
          @buffer = ''.b
          buf
        else
          @buffer.freeze
          rbuf = @buffer.byteslice(0, size)
          @buffer = @buffer.byteslice(size, @buffer.bytesize)
          rbuf
        end
      end
    end
  end
end
