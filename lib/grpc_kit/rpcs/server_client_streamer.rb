# frozen_string_literal: true

require 'grpc_kit/rpcs'
require 'grpc_kit/calls/server_client_streamer'

module GrpcKit
  module Rpcs::Server
    class ClientStreamer < GrpcKit::Rpcs::ServerRpc
      # @param stream [GrpcKit::Stream::ServerStream]
      # @param metadata [Hash<String, String>]
      # @return [void]
      def invoke(stream, metadata: {})
        call = GrpcKit::Calls::Server::ClientStreamer.new(
          metadata: metadata,
          config: @config,
          stream: stream,
        )

        if @config.interceptor
          @config.interceptor.intercept(call) do |c|
            resp = @handler.send(@config.ruby_style_method_name, c)
            c.send_msg(resp)
          end
        else
          resp = @handler.send(@config.ruby_style_method_name, call)
          call.send_msg(resp)
        end
      end
    end
  end
end
