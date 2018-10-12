# frozen_string_literal: true

require 'grpc_kit/grpc/dsl'

module GrpcKit
  module GRPC
    class Interceptor
      def initialize(options = {})
        @options = options
      end
    end

    class ClientInterceptor < Interceptor
      def request_response(request: nil, call: nil, method: nil, metadata: nil)
        yield
      end

      def client_streamer(requests: nil, call: nil, method: nil, metadata: nil)
        yield
      end

      def server_streamer(request: nil, call: nil, method: nil, metadata: nil)
        yield
      end

      def bidi_streamer(requests: nil, call: nil, method: nil, metadata: nil)
        yield
      end
    end

    class ServerInterceptor < Interceptor
      def request_response(request: nil, call: nil, method: nil)
        yield
      end

      def client_streamer(call: nil, method: nil)
        yield
      end

      def server_streamer(request: nil, call: nil, method: nil)
        yield
      end

      def bidi_streamer(requests: nil, call: nil, method: nil)
        yield
      end
    end
  end
end
