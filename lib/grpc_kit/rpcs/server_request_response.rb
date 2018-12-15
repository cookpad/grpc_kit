# frozen_string_literal: true

require 'grpc_kit/rpcs'
require 'grpc_kit/calls/server_request_response'

module GrpcKit
  module Rpcs::Server
    class RequestResponse < GrpcKit::Rpcs::ServerRpc
      # @param stream [GrpcKit::Stream::ServerStream]
      # @param metadata [Hash<String, String>]
      # @return [void]
      def invoke(stream, metadata: {})
        call = GrpcKit::Calls::Server::RequestResponse.new(
          metadata: metadata,
          config: @config,
          stream: stream,
        )

        request = call.recv(last: true)
        resp =
          if @config.interceptor
            @config.interceptor.intercept(request, call) do
              @handler.send(@config.ruby_style_method_name, request, call)
            end
          else
            @handler.send(@config.ruby_style_method_name, request, call)
          end

        call.send_msg(resp, last: true)
      end
    end
  end
end
