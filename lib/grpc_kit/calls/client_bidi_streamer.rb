# frozen_string_literal: true

require 'grpc_kit/call'
require 'grpc_kit/calls'

module GrpcKit
  module Calls::Client
    class BidiStreamer < GrpcKit::Call
      include Enumerable

      alias outgoing_metadata metadata

      def initialize(*)
        super
        @recv_mutex = Mutex.new

        @send = false
        @send_cv = Thread::ConditionVariable.new
        @send_mutex = Mutex.new
      end

      # @param data [Object] request message
      # @return [void]
      def send_msg(data)
        if @reason
          raise "Upstream returns an error status: #{@reason}"
        end

        @send_mutex.synchronize do
          @stream.send_msg(data, metadata: outgoing_metadata)
          @send = true
          @send_cv.broadcast
        end
      end

      # Receive a message from peer. This method is not thread safe, never call from multiple threads at once.
      # @return [Object] response object
      # @raise [StopIteration]
      def recv
        @send_mutex.synchronize { @send_cv.wait(@send_mutex) until @send } unless @send

        msg = @stream.recv_msg(blocking: true)
        return msg if msg
        raise StopIteration
      rescue GrpcKit::Errors::BadStatus => e
        @reason = e
        raise e
      end

      def close_and_send
        @send_mutex.synchronize do
          @stream.close_and_send
        end
      end

      # @yieldparam response [Object] each response object of bidi streaming RPC
      def each
        @recv_mutex.synchronize do
          loop { yield(recv) }
        end
      end
    end
  end
end
