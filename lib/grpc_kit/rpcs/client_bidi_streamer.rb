# frozen_string_literal: true

require 'grpc_kit/rpcs'
require 'grpc_kit/calls/client_bidi_streamer'

module GrpcKit
  module Rpcs::Client
    class BidiStreamer < GrpcKit::Rpcs::ClientRpc
      # @param stream [GrpcKit::Stream::ClientStream]
      # @param _requests [Object] it's for compatibility, no use
      # @param metadata [Hash<String, String>]
      # @param timeout [GrpcKit::GrpcTime]
      # @return [GrpcKit::Calls::Client::BidiStreamer]
      def invoke(stream, _requests, metadata: {}, timeout: nil)
        call = GrpcKit::Calls::Client::BidiStreamer.new(
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
