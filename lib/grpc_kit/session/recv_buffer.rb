# frozen_string_literal: true

module GrpcKit
  module Session
    class RecvBuffer
      def initialize
        @buffer = +''.b
        @end = false
      end

      def write(data)
        @buffer << data
      end

      def read(size = nil, last: false)
        return nil if @buffer.empty?

        end_read if last

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

      def end_read?
        @end
      end

      def end_read
        @end = true
      end
    end
  end
end
