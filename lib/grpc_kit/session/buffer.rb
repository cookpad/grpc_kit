module GrpcKit
  module Session
    class Buffer
      attr_accessor :finish

      def initialize(buffer: nil)
        @buffer = buffer
        @end_read = false
        @end_write = false
        @finish = false
        @write_byte_size = 0
      end

      def write(data, last: false)
        end_write if last
        @write_byte_size += data.size

        if @buffer
          @buffer << data
        else
          @buffer = data
        end
      end

      def read(len = nil, last: false)
        end_read if last

        if @buffer.nil?
          return ''
        end

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
