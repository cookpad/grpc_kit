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

        @send = true
      end

      # This method not is expected to be call in the main thread where #send_msg is called
      #
      # @return [Object] response object
      def recv
        sleep 0.1 until @send

        loop do
          msg = @mutex.synchronize do
            @stream.recv_msg(blocking: false)
          end

          unless msg == :wait_readable
            return msg
          end
        end

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
