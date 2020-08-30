# frozen_string_literal: true

require 'grpc_kit/call'
require 'grpc_kit/calls'

module GrpcKit
  module Calls::Server
    class BidiStreamer < GrpcKit::Call
      include Enumerable

      attr_reader :outgoing_initial_metadata, :outgoing_trailing_metadata
      alias incoming_metadata metadata

      def initialize(*)
        super

        @outgoing_initial_metadata = {}
        @outgoing_trailing_metadata = {}
      end

      # @param data [Object] request message
      # @return [void]
      def send_msg(data)
        @stream.send_msg(
          data,
          @codec,
          initial_metadata: @outgoing_initial_metadata,
          trailing_metadata: @outgoing_trailing_metadata,
          limit_size: @config.max_send_message_size,
        )
      end

      # This method is not thread safe, never call from multiple threads at once.
      # @return [Object] response object
      def recv
        @stream.recv_msg(@codec, limit_size: @config.max_receive_message_size)
      end

      # @yieldparam response [Object] each response object of bidi streaming RPC
      def each
        loop { yield(recv) }
      end
    end
  end
end
