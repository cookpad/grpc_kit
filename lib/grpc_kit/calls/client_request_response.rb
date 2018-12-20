# frozen_string_literal: true

require 'grpc_kit/call'
require 'grpc_kit/calls'

module GrpcKit
  module Calls::Client
    class RequestResponse < GrpcKit::Call
      alias outgoing_metadata metadata

      # @param data [Object] request message
      # @return [void]
      def send_msg(data)
        @stream.send_msg(data, last: true, metadata: outgoing_metadata)
      end

      # @return [Object] response object
      def recv
        @stream.recv_msg(last: true)
      end
    end
  end
end
