# frozen_string_literal: true

require 'grpc_kit/interceptors'

module GrpcKit
  module Interceptors::Client
    class RequestResponse
      # @param interceptors [Array<GrpcKit::GRPC::ClientInterceptor>]
      def initialize(interceptors)
        @interceptors = interceptors
      end

      # @param call [GrpcKit::Calls::Client::RequestResponse]
      # @param metadata [Hash<String,String>]
      # @yieldreturn [Object] Response object server sent
      def intercept(request, call, metadata, &block)
        if @interceptors && !@interceptors.empty?
          do_intercept(@interceptors.dup, request, call, metadata, &block)
        else
          yield
        end
      end

      private

      def do_intercept(interceptors, request, call, metadata)
        if interceptors.empty?
          return yield
        end

        interceptor = interceptors.pop
        interceptor.request_response(request: request, call: call, method: call.method, metadata: metadata) do
          do_intercept(interceptors, request, call, metadata) do
            yield
          end
        end
      end
    end
  end
end
