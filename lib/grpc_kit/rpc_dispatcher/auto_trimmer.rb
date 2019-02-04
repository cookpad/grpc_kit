# frozen_string_literal: true

module GrpcKit
  class RpcDispatcher
    class AutoTrimmer
      def initialize(pool, interval: 30)
        @pool = pool
        @interval = interval
        @running = false
      end

      def start!
        @running = true
        @thread = Thread.new do
          loop do
            unless @running
              GrpcKit.logger.debug('Stop AutoTrimer')
              break
            end
            @pool.trim
            sleep @interval
          end
        end
      end

      def stop
        @running = false
        @thread.wakeup
      end
    end
  end
end
