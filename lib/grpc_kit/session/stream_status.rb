# frozen_string_literal: true

module GrpcKit
  module Session
    class StreamStatus
      OPEN              = 0
      CLOSE             = 1
      HALF_CLOSE_REMOTE = 2
      HALF_CLOSE_LOCAL  = 3

      def initialize
        @status = OPEN
      end

      # @return [void]
      def close_local
        if @status == OPEN
          @status = HALF_CLOSE_LOCAL
        elsif @status == HALF_CLOSE_REMOTE
          @status = CLOSE
        elsif @status == HALF_CLOSE_LOCAL
        # nothing
        else
          raise 'stream is already closed'
        end
      end

      # @return [void]
      def close_remote
        if @status == OPEN
          @status = HALF_CLOSE_REMOTE
        elsif @status == HALF_CLOSE_LOCAL
          @status = CLOSE
        elsif @status == HALF_CLOSE_REMOTE
        # nothing
        else
          raise 'stream is already closed'
        end
      end

      # @return [void]
      def close
        @status = CLOSE
      end

      # @return [Boolean]
      def close_local?
        (@status == HALF_CLOSE_LOCAL) || close?
      end

      # @return [Boolean]
      def close_remote?
        (@status == HALF_CLOSE_REMOTE) || close?
      end

      # @return [Boolean]
      def close?
        @status == CLOSE
      end
    end
  end
end
