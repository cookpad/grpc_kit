# frozen_string_literal: true

require 'grpc_kit/interceptors'

module GrpcKit
  module Interceptors::Client
    class BidiStreamer < Streaming
      private

      def invoke(interceptor, call, metadata)
        interceptor.bidi_streamer(requests: nil, call: call, method: call.method, metadata: metadata) do
          yield(call, metadata)
        end
      end
    end
  end
end
