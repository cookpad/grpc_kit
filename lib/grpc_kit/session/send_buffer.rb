# frozen_string_literal: true

module GrpcKit
  module Session
    class SendBuffer
      def initialize
        @buffer = ''.b
        @end_write = false
        @deferred_read = false
        @mutex = Mutex.new
      end

      # @param data [String]
      # @param last [Boolean]
      # @return [void]
      def write(data, last: false)
        @mutex.synchronize { @buffer << data }
        end_write if last
      end

      # @return [Boolean]
      def need_resume?
        @deferred_read
      end

      def no_resume
        @deferred_read = false
      end

      # @return [void]
      def end_write
        @end_write = true
      end

      # @return [Boolean]
      def end_write?
        @end_write
      end

      def empty?
        @mutex.synchronize { @buffer.empty? }
      end

      # @param size [Integer,nil]
      # @return [nil,DS9::ERR_DEFERRED,String]
      def read(size = nil)
        buf = do_read(size)
        if buf
          @deferred_read = false
          return buf
        end

        if end_write?
          # Call again because #write invokes `@buffer << data` before calling #end_write
          if (buf = do_read(size))
            @deferred_read = false
            return buf
          end

          @deferred_read = false
          return nil # EOF
        end

        @deferred_read = true
        DS9::ERR_DEFERRED
      end

      private

      def do_read(size = nil)
        @mutex.synchronize do
          if @buffer.empty?
            nil
          elsif size.nil? || @buffer.bytesize < size
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
end
