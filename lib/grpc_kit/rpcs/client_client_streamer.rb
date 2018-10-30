# frozen_string_literal: true

require 'grpc_kit/rpcs'
require 'grpc_kit/calls/client_client_streamer'

module GrpcKit
  module Rpcs::Client
    class ClientStreamer < GrpcKit::Rpcs::ClientRpc
      def invoke(stream, _request, metadata: {}, timeout: nil)
        call = GrpcKit::Calls::Client::ClientStreamer.new(
          metadata: metadata,
          config: @config,
          timeout: timeout,
          stream: stream,
        )

        @config.interceptor.intercept(call, metadata) do |s|
          s
        end
      end
    end
  end
end
