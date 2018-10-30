# frozen_string_literal: true

require 'grpc_kit/rpcs'
require 'grpc_kit/calls/client_request_response'

module GrpcKit
  module Rpcs::Client
    class RequestResponse < GrpcKit::Rpcs::ClientRpc
      def invoke(stream, request, metadata: {}, timeout: nil)
        call = GrpcKit::Calls::Client::RequestResponse.new(
          metadata: metadata,
          config: @config,
          timeout: timeout,
          stream: stream,
        )

        @config.interceptor.intercept(request, call, call.metadata) do |r, c, _|
          if timeout
            Timeout.timeout(timeout.to_f, GrpcKit::Errors::DeadlineExceeded) do
              call.send_msg(r, timeout: timeout.to_s, metadata: c.metadata, last: true)
              call.recv(last: true)
            end
          else
            call.send_msg(r, metadata: c.metadata, last: true)
            call.recv(last: true)
          end
        end
      end
    end
  end
end
