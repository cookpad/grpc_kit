# frozen_string_literal: true

require 'grpc_kit/calls'

module GrpcKit
  module Calls::Client
    class BidiStreamer < GrpcKit::Calls::Call
      attr_reader :deadline, :service_name, :method_name
      attr_reader :metadata
      alias outgoing_metadata metadata

      def initialize(*)
        super
        @mutex = Mutex.new
        @send = false
      end

      def send_msg(data, last: false)
        raise 'No method error' if @restrict

        @mutex.synchronize do
          @stream.send_msg(data, last: last, metadata: outgoing_metadata)
        end

        @send = true
      end

      class WouldBlock < StandardError; end

      def recv(last: false)
        raise 'No method error' if @restrict

        sleep 0.1 until @send

        msg = @mutex.synchronize do
          @stream.recv_msg(last: last, blocking: false)
        end

        raise WouldBlock if msg == :wait_readable

        msg
      rescue WouldBlock => _
        retry
      end

      def close_and_send
        @mutex.synchronize do
          @stream.close_and_send
        end
      end
    end
  end
end
