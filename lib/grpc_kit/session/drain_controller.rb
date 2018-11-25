# frozen_string_literal: true

require 'ds9'

module GrpcKit
  module Session
    class DrainController
      def initialize
        @sent_shutdown_notice = false
        @goaway_sent = false
        @after_one_rtt = false
        # @sent_ping = false
      end

      # @return [void]
      def recv_ping_ack
        @after_one_rtt = true
      end

      # @return [void]
      def call(session)
        if @goaway_sent
        # session.shutdown
        elsif @sent_shutdown_notice && @after_one_rtt
          session.submit_goaway(DS9::NO_ERROR, session.last_proc_stream_id)
          @goaway_sent = true
        # elsif @sent_shutdown_notice && !@after_one_rtt && !@sent_ping
        # @sent_ping = true
        elsif !@sent_shutdown_notice
          session.submit_shutdown
          @sent_shutdown_notice = true
          session.submit_ping # wait for 1 RTT
        end
      end
    end
  end
end
