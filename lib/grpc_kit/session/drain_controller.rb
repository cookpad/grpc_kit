# frozen_string_literal: true

require 'ds9'

module GrpcKit
  module Session
    class DrainController
      module Status
        NOT_START = 0
        STARTED = 1
        SENT_SHUTDOWN = 2
        SENT_PING = 3
        RECV_PING_ACK = 4
        SENT_GOAWAY = 5
      end

      def initialize(draining_time = 5)
        @draining_time = draining_time
        @status = Status::NOT_START
      end

      def start_draining?
        @status > Status::NOT_START
      end

      def start_draining
        @status = Status::STARTED
      end

      # @return [void]
      def recv_ping_ack
        if @status == Status::SENT_PING
          next_step
        end
      end

      # @return [void]
      def next(session)
        case @status
        when Status::NOT_START
          # next_step
        when Status::STARTED
          session.submit_shutdown
          next_step
        when Status::SENT_SHUTDOWN
          session.submit_ping
          @sent_time = Time.now.to_i
          next_step
        when Status::SENT_PING
          # skip until #recv_ping_ack is called (1RTT)
        when Status::RECV_PING_ACK
          if @sent_time && (Time.now.to_i - @sent_time) > @draining_time
            return
          end

          session.submit_goaway(session.last_proc_stream_id, DS9::NO_ERROR)
          next_step
        when Status::SENT_GOAWAY
          # session.shutdown
        end
      end

      private

      def next_step
        @status += 1
      end
    end
  end
end
