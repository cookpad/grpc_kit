# frozen_string_literal: true

require 'grpc_kit/rpcs'
require 'grpc_kit/calls/client_client_streamer'

module GrpcKit
  module Rpcs::Client
    class ClientStreamer < GrpcKit::Rpcs::ClientRpc
      # @param stream [GrpcKit::Stream::ClientStream]
      # @param _request [nil] No use
      # @param metadata [Hash<String, String>]
      # @param timeout [GrpcKit::GrpcTime]
      # @return [GrpcKit::Calls::Client::ClientStreamer]
      def invoke(stream, _request, metadata: {}, timeout: nil)
        call = GrpcKit::Calls::Client::ClientStreamer.new(
          metadata: metadata,
          config: @config,
          timeout: timeout,
          stream: stream,
        )

        if @config.interceptor
          @config.interceptor.intercept(call, metadata) { |c| c }
        else
          call
        end
      end
    end
  end
end
