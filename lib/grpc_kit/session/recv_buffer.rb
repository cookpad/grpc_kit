# frozen_string_literal: true

module GrpcKit
  module Session
    class RecvBuffer
      def initialize
        @buffer = +''.b
        @end = false
        @mutex = Mutex.new
      end

      # @param data [String]
      # @return [void]
      def write(data)
        @mutex.synchronize { @buffer << data }
      end

      # @param size [Integer,nil]
      # @param last [Boolean]
      # @return [String,nil]
      def read(size = nil, last: false)
        buf = @mutex.synchronize do
          return nil if @buffer.empty?

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

        end_read if last
        buf
      end

      # @return [Boolean]
      def end_read?
        @end
      end

      # @return [void]
      def end_read
        @end = true
      end
    end
  end
end
