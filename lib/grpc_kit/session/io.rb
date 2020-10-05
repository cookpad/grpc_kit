# frozen_string_literal: true

require 'ds9'

module GrpcKit
  module Session
    class IO
      def initialize(io)
        @io = io
        @wake_o, @wake_i = ::IO.pipe
      end

      def close
        @wake_i.close
        @wake_o.close
        @io.close
      end

      # @param length [Integer]
      # @return [DS9::ERR_WOULDBLOCK, DS9::ERR_EOF, String]
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

      # @param data [String]
      # @return [DS9::ERR_WOULDBLOCK, Integer]
      def send_event(data)
        return 0 if data.empty?

        bytes = @io.write_nonblock(data, exception: false)
        if bytes == :wait_writable
          DS9::ERR_WOULDBLOCK
        else
          bytes
        end
      end

      # Blocking until io object is readable
      # @return [void]
      def wait_readable
        ::IO.select([@io], [], [])
        true
      rescue IOError
        false
      end

      # Blocking until io object is readable or writable
      # @return [void]
      def select(timeout: 1, write: true)
        rs, ws = ::IO.select([@io, @wake_o], write ? [@io] : [], [], timeout)
        @wake_o.read(@wake_o.stat.size) if rs&.delete(@wake_o) && !@wake_o.closed?
        [rs || [], ws || []]
      end

      # Wake thread blocked at #select method
      # @param [Symbol] Indicate what event needed to invoke blocking thread. This argument is for debugging purpose.
      def wake!(memo = nil)
        @wake_i.write_nonblock(?\0, exception: false)
      rescue Errno::EPIPE
      rescue IOError
        raise unless @wake_i.closed?
      end

      # @return [void]
      def flush
        @io.flush
      end
    end
  end
end
