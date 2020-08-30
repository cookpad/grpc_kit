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
        @mutex = Mutex.new

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

        @mutex.synchronize do
          @stream.send_msg(data, metadata: outgoing_metadata)
        end

        @send_mutex.synchronize do
          @send = true
          @send_cv.broadcast
        end
      end

      # This method not is expected to be call in the main thread where #send_msg is called
      #
      # @return [Object] response object
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
        @mutex.synchronize do
          @stream.close_and_send
        end
      end

      # @yieldparam response [Object] each response object of bidi streaming RPC
      def each
        loop { yield(recv) }
      end
    end
  end
end
