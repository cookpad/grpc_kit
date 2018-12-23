# frozen_string_literal: true

require 'grpc_kit/interceptors'

module GrpcKit
  module Interceptors::Client
    class BidiStreamer < Streaming
      private

      # @param interceptor [GrpcKit::Grpc::ClientInterceptor]
      # @param call [GrpcKit::Calls::Client::BidiStreamer]
      # @param metadata [Hash<String,String>]
      def invoke(interceptor, call, metadata)
        interceptor.bidi_streamer(requests: nil, call: call, method: call.method, metadata: metadata) do |new_call = nil|
          yield(new_call || call, metadata)
        end
      end
    end
  end
end
