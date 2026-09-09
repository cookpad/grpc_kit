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
      # @return [Boolean] false when the io object is already closed
      def wait_readable
        ::IO.select([@io], [], [])
        true
      rescue IOError
        false
      end

      # Blocking until io object is readable or writable
      # @param timeout [Integer, Float, nil] seconds to wait, or nil to block forever
      # @param write [Boolean] whether to wait for writability as well
      # @return [Array(Array<::IO>, Array<::IO>)] readable ios and writable ios, both empty on timeout.
      def select(timeout: 1, write: true)
        rs, ws = ::IO.select([@io, @wake_o], write ? [@io] : [], [], timeout)
        drain_waker if rs&.delete(@wake_o)
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

      private

      # @return [void]
      def drain_waker
        return if @wake_o.closed?

        loop do
          data = @wake_o.read_nonblock(4096, exception: false)
          break if [:wait_readable, nil].include?(data) # EAGAIN, EWOULDBLOCK, or EOF
        end
      end
    end
  end
end
