# frozen_string_literal: true

require 'grpc_kit/rpcs'
require 'grpc_kit/calls/client_server_streamer'

module GrpcKit
  module Rpcs::Client
    class ServerStreamer < GrpcKit::Rpcs::ClientRpc
      # @param stream [GrpcKit::Stream::ClientStream]
      # @param request [Object] reqeust message
      # @param metadata [Hash<String, String>]
      # @param timeout [GrpcKit::GrpcTime]
      # @return [GrpcKit::Calls::Client::ServerStreamer]
      def invoke(stream, request, metadata: {}, timeout: nil)
        call = GrpcKit::Calls::Client::ServerStreamer.new(
          metadata: metadata,
          config: @config,
          timeout: timeout,
          stream: stream,
        )

        if @config.interceptor
          @config.interceptor.intercept(call, metadata) do |c|
            c.send_msg(request)
            c
          end
        else
          call.send_msg(request)
          call
        end
      end
    end
  end
end
