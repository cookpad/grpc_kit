# frozen_string_literal: true

require 'grpc_kit/call'
require 'grpc_kit/calls'

module GrpcKit
  module Calls::Client
    class ServerStreamer < GrpcKit::Call
      include Enumerable

      alias outgoing_metadata metadata

      # @param data [Object] request message
      # @return [void]
      def send_msg(data)
        @stream.send_msg(data, last: true, metadata: outgoing_metadata)
      end

      # This method is not thread safe, never call from multiple threads at once.
      # @return [Object] response object
      def recv
        @stream.recv_msg
      end

      # @yieldparam response [Object] each response object of server streaming RPC
      def each
        loop { yield(recv) }
      end
    end
  end
end
