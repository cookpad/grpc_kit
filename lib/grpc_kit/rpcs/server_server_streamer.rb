# frozen_string_literal: true

require 'grpc_kit/rpcs'
require 'grpc_kit/calls/server_server_streamer'

module GrpcKit
  module Rpcs::Server
    class ServerStreamer < GrpcKit::Rpcs::ServerRpc
      # @param stream [GrpcKit::Stream::ServerStream]
      # @param metadata [Hash<String, String>]
      # @return [void]
      def invoke(stream, metadata: {})
        call = GrpcKit::Calls::Server::ServerStreamer.new(
          metadata: metadata,
          config: @config,
          stream: stream,
        )

        if @config.interceptor
          @config.interceptor.intercept(call) do |c|
            request = c.recv
            @handler.send(@config.ruby_style_method_name, request, c)
          end
        else
          request = call.recv
          @handler.send(@config.ruby_style_method_name, request, call)
        end

        stream.send_status
      end
    end
  end
end
