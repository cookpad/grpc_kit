# frozen_string_literal: true

require 'grpc_kit/rpcs'
require 'grpc_kit/calls/client_request_response'

module GrpcKit
  module Rpcs::Client
    class RequestResponse < GrpcKit::Rpcs::ClientRpc
      # @param stream [GrpcKit::Stream::ClientStream]
      # @param request [Object] request message
      # @param metadata [Hash<String, String>]
      # @param timeout [GrpcKit::GrpcTime]
      # @return [Object] response message
      def invoke(stream, request,  metadata: {}, timeout: nil)
        call = GrpcKit::Calls::Client::RequestResponse.new(
          metadata: metadata,
          config: @config,
          timeout: timeout,
          stream: stream,
        )

        Timeout.timeout(timeout&.to_f, GrpcKit::Errors::DeadlineExceeded) do
          if @config.interceptor
            @config.interceptor.intercept(request, call, call.metadata) do |r, c, _|
              call.send_msg(request, last: true)
              call.recv(last: true)
            end
          else
            call.send_msg(request, last: true)
            call.recv(last: true)
          end
        end
      end
    end
  end
end
