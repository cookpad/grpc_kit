# frozen_string_literal: true

require 'grpc_kit/call'
require 'grpc_kit/calls'

module GrpcKit
  module Calls::Server
    class RequestResponse < GrpcKit::Call
      attr_reader :outgoing_initial_metadata, :outgoing_trailing_metadata
      alias incoming_metadata metadata

      def initialize(*)
        super

        @outgoing_initial_metadata = {}
        @outgoing_trailing_metadata = {}
      end

      # @param data [Object] request message
      # @param last [Boolean]
      # @return [void]
      def send_msg(data)
        @stream.send_msg(
          data,
          @codec,
          last: true,
          initial_metadata: @outgoing_initial_metadata,
          trailing_metadata: @outgoing_trailing_metadata,
          limit_size: @config.max_send_message_size,
        )
      end

      # @return [Object] response object
      def recv
        @stream.recv_msg(@codec, last: true, limit_size: @config.max_receive_message_size)
      end
    end
  end
end
