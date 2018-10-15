# frozen_string_literal: true

require 'ds9'

module GrpcKit
  module IO
    class Basic
      def initialize(reader, writer)
        @reader = reader
        @writer = writer
      end

      def close
        @reader.close_read
        @writer.close_write
      end

      def read(length)
        data = @reader.read_nonblock(length, nil, exception: false)

        case data
        when :wait_readable
          DS9::ERR_WOULDBLOCK
        when nil # EOF
          DS9::ERR_EOF
        else
          data
        end
      end

      def write(data)
        @writer.write(data)
      end

      def wait_readable
        @reader.wait_writable
      end
    end
  end
end
