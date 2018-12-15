# frozen_string_literal: true

require 'grpc_kit/interceptors'

module GrpcKit
  module Interceptors::Server
    class RequestResponse
      # @param interceptors [Array<GrpcKit::GRPC::ServerInterceptor>]
      def initialize(interceptors)
        @interceptors = interceptors
      end

      # @param request [Object] Recevied request objects
      # @param call [GrpcKit::Calls::Client::RequestResponse]
      # @yieldreturn [Object] Response object server sent
      def intercept(request, call, &block)
        if @interceptors && !@interceptors.empty?
          do_intercept(@interceptors.dup, request, call, &block)
        else
          yield
        end
      end

      private

      def do_intercept(interceptors, request, call)
        if interceptors.empty?
          return yield
        end

        interceptor = interceptors.pop
        interceptor.request_response(request: request, call: call, method: call.method) do
          do_intercept(interceptors, request, call) { yield }
        end
      end
    end
  end
end
