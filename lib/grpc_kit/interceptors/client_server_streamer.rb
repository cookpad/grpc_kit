# frozen_string_literal: true

require 'grpc_kit/interceptors'

module GrpcKit
  module Interceptors::Client
    class ServerStreamer < Streaming
      private

      # @param interceptor [GrpcKit::Grpc::ClientInterceptor]
      # @param call [GrpcKit::Calls::Client::ServerStreamer]
      # @param metadata [Hash<String,String>]
      def invoke(interceptor, call, metadata)
        # We don't need a `:request` parameter but,
        # it shuoldn't remove from paramters due to having a compatibility of grpc gem.
        interceptor.server_streamer(request: nil, call: call, method: call.method, metadata: metadata) do |new_call = nil|
          yield(new_call || call, metadata)
        end
      end
    end
  end
end
