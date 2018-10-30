# frozen_string_literal: true

require 'grpc_kit/rpcs'
require 'grpc_kit/calls/client_server_streamer'

module GrpcKit
  module Rpcs::Client
    class ServerStreamer < GrpcKit::Rpcs::ClientRpc
      def invoke(stream, request, metadata: {}, timeout: nil)
        call = GrpcKit::Calls::Client::ServerStreamer.new(metadata: metadata, config: @config, timeout: timeout, stream: stream)

        @config.interceptor.intercept(call, metadata) do |c, m|
          c.send_msg(request, metadata: m, last: true)
          c
        end
      end
    end
  end
end
