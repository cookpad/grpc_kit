# frozen_string_literal: true

require 'grpc_kit/interceptors/streaming'

module GrpcKit
  module Interceptors
    module Client
      class ServerStreamer < Streaming
        private

        def invoke(interceptor, call)
          # We don't need a `:request` parameter but,
          # it shuoldn't remove from paramters due to having a compatibility of grpc gem.
          interceptor.server_streamer(request: nil, call: call, method: call.method, metadata: nil) do |s|
            yield(s)
          end
        end
      end
    end

    module Server
      class ServerStreamer < Streaming
        def invoke(interceptor, call)
          # We don't need a `:request` parameter but,
          # it shuoldn't remove from paramters due to having a compatibility of grpc gem.
          interceptor.server_streamer(request: nil, call: call, method: call.method) do |s|
            yield(s)
          end
        end
      end
    end
  end
end
