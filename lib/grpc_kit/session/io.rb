# frozen_string_literal: true

require 'ds9'

module GrpcKit
  module Session
    class IO
      def initialize(io)
        @io = io
      end

      def close
        @io.close
      end

      def recv_event(length)
        data = @io.read_nonblock(length, nil, exception: false)

        case data
        when :wait_readable
          DS9::ERR_WOULDBLOCK
        when nil # nil means EOF
          DS9::ERR_EOF
        else
          data
        end
      end

      def send_event(data)
        return 0 if data.empty?

        bytes = @io.write_nonblock(data, exception: false)
        if bytes == :wait_writable
          DS9::ERR_WOULDBLOCK
        else
          bytes
        end
      end

      def wait_readable
        @io.wait_writable
      end

      def flush
        @io.flush
      end
    end
  end
end
