# frozen_string_literal: true

require 'grpc_kit/call'
require 'grpc_kit/calls'

module GrpcKit
  module Calls::Client
    class ClientStreamer < GrpcKit::Call
      alias outgoing_metadata metadata

      # @param data [Object] request message
      # @return [void]
      def send_msg(data)
        @stream.send_msg(data, metadata: outgoing_metadata)
      end

      # @return [Object] response object
      def recv
        @stream.close_and_recv
      end
    end
  end
end
