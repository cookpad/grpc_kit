# frozen_string_literal: true

require 'ds9'

module GrpcKit
  module Session
    class DrainController
      module Status
        NOT_START = 0
        STARTED = 1
        SENT_PING = 2
        RECV_PING_ACK = 3
        SENT_GOAWAY = 4
      end

      def initialize
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
          session.submit_ping
          next_step
        when Status::SENT_PING
          # skip until #recv_ping_ack is called (1RTT)
        when Status::RECV_PING_ACK
          session.submit_goaway(DS9::NO_ERROR, session.last_proc_stream_id)
          next_step
        when Status::SENT_GOAWAY
          session.shutdown
        end
      end

      private

      def next_step
        @status += 1
      end
    end
  end
end
