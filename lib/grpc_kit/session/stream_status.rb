# frozen_string_literal: false

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

      def close_local
        if @status == OPEN
          @status = HALF_CLOSE_LOCAL
        elsif @status == HALF_CLOSE_REMOTE
          @status = CLOSE
        elsif @status == HALF_CLOSE_REMOTE
        # nothing
        else
          raise 'stream is already closed'
        end
      end

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

      def close
        @status = CLOSE
      end

      def remote_close?
        (@status == HALF_CLOSE_REMOTE) || close?
      end

      def local_close?
        (@status == HALF_CLOSE_LOCAL) || close?
      end

      def close?
        @status == CLOSE
      end
    end
  end
end
