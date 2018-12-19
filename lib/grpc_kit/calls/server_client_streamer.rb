# frozen_string_literal: true

require 'grpc_kit/call'
require 'grpc_kit/calls'

module GrpcKit
  module Calls::Server
    class ClientStreamer < GrpcKit::Call
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
      def send_msg(data, last: false)
        @stream.send_msg(
          data,
          @protobuf,
          last: last,
          initial_metadata: @outgoing_initial_metadata,
          trailing_metadata: @outgoing_trailing_metadata,
          limit_size: @config.max_send_message_size,
        )
      end

      # @param last [Boolean]
      # @return [Object] response object
      def recv(last: false)
        @stream.recv_msg(@protobuf, last: last, limit_size: @config.max_receive_message_size)
      end
    end
  end
end
