# frozen_string_literal: true

require 'grpc_kit/interceptors'

module GrpcKit
  module Interceptors::Server
    class BidiStreamer < Streaming
      # @param interceptor [GrpcKit::Grpc::ServerInterceptor]
      # @param call [GrpcKit::Calls::Client::BidiStreamer]
      def invoke(interceptor, call)
        interceptor.bidi_streamer(call: call, method: call.method) do |new_call = nil|
          yield(new_call || call)
        end
      end
    end
  end
end
