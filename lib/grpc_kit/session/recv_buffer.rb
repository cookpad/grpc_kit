# frozen_string_literal: true

module GrpcKit
  module Session
    class RecvBuffer
      class Closed < Exception; end

      def initialize
        @buffer = +''.b
        @end = false
        @queue = Queue.new
      end

      # @param data [String]
      # @return [void]
      def write(data)
        @queue << data
      rescue ClosedQueueError
        raise Closed, "[BUG] write to closed queue"
      end

      # @return [Boolean]
      def empty?
        @queue.empty?
      end

      # @return [Boolean]
      def closed?
        @queue.closed?
      end

      # @return [void]
      def close
        @queue.close
      end

      # This method is not thread safe (as RecvBuffer is designed to be a multi-producer/single-consumer)
      # @param size [Integer,nil]
      # @param last [Boolean]
      # @param blocking [Boolean]
      # @return [String,Symbol,nil]
      def read(size = nil, last: false, blocking:)
        if @buffer.empty?
          return nil if empty? && closed?
          return :wait_readable if empty? && !blocking

          # Consume existing data as much as possible to continue (important on clients where single-threaded)
          loop do
            begin
              data = @queue.shift(!blocking)
              @buffer << data if data
            rescue ThreadError, ClosedQueueError
              break
            end

            break if empty?
          end 
        end

        buf = if size.nil? || @buffer.bytesize < size
          rbuf = @buffer
          @buffer = ''.b
          rbuf
        else
          @buffer.freeze
          rbuf = @buffer.byteslice(0, size)
          @buffer = @buffer.byteslice(size, @buffer.bytesize)
          rbuf
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
