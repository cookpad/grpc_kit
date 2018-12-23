# frozen_string_literal: true

require 'grpc_kit/grpc/dsl'

module GrpcKit
  module Grpc
    class Interceptor
      def initialize(options = {})
        @options = options
      end
    end

    class ClientInterceptor < Interceptor
      # rubocop:disable Lint/UnusedMethodArgument

      # @param request [Object,nil] An object which cliet will send
      # @param call [GrpcKit::Calls::Client::RequestResponse,nil]
      # @param metadata [Hash<String,String>,nil]
      # @param method [GrpcKit::Call::Name,nil]
      def request_response(request: nil, call: nil, method: nil, metadata: nil)
        yield
      end

      # @param requests [Object,nil] comptibility with grpc gem, no use
      # @param call [GrpcKit::Calls::Client::ClientStreamer,nil]
      # @param metadata [Hash<String,String>,nil]
      # @param method [GrpcKit::Call::Name,nil]
      def client_streamer(requests: nil, call: nil, method: nil, metadata: nil)
        yield
      end

      # @param request [Object,nil] An object which cliet will send
      # @param call [GrpcKit::Calls::Client::ServerStreamer,nil]
      # @param metadata [Hash<String,String>,nil]
      # @param method [GrpcKit::Call::Name,nil]
      def server_streamer(request: nil, call: nil, method: nil, metadata: nil)
        yield
      end

      # @param requests [Object,nil] comptibility with grpc gem, no use
      # @param call [GrpcKit::Calls::Client::BidiStreamer,nil]
      # @param metadata [Hash<String,String>,nil]
      # @param method [GrpcKit::Call::Name,nil]
      def bidi_streamer(requests: nil, call: nil, method: nil, metadata: nil)
        yield
      end

      # rubocop:enable Lint/UnusedMethodArgument
    end

    class ServerInterceptor < Interceptor
      # rubocop:disable Lint/UnusedMethodArgument

      # @param request [Object] An object which server received
      # @param call [GrpcKit::Calls::Server::RequestResponse,nil]
      # @param method [GrpcKit::Call::Name,nil]
      def request_response(request: nil, call: nil, method: nil)
        yield
      end

      # @param call [GrpcKit::Calls::Server::ClientStreamer,nil]
      # @param method [GrpcKit::Call::Name,nil]
      def client_streamer(call: nil, method: nil)
        yield
      end

      # @param request [Object] An object which server received
      # @param call [GrpcKit::Calls::Server::ServerStreamer,nil]
      # @param method [GrpcKit::Call::Name,nil]
      def server_streamer(request: nil, call: nil, method: nil)
        yield
      end

      # @param requests [Object,nil] comptibility with grpc gem, no use
      # @param call [GrpcKit::Calls::Server::BidiStreamer,nil]
      # @param method [GrpcKit::Call::Name,nil]
      def bidi_streamer(requests: nil, call: nil, method: nil)
        yield
      end

      # rubocop:enable Lint/UnusedMethodArgument
    end
  end
end
