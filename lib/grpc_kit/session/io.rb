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
        remain = data.bytesize
        size = remain
        while remain > 0
          begin
            remain -= @io.syswrite(data)
          rescue Errno::EAGAIN, Errno::EWOULDBLOCK
            unless IO.select(nil, [io], nil, 1)
              raise 'timeout writing data'
            end
          rescue IOError => e
            raise IOError, e # TODO
          end

          data = data.byteslice(remain..-1)
        end

        size
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
