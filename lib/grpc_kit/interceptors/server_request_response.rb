# frozen_string_literal: true

require 'grpc_kit/interceptors'

module GrpcKit
  module Interceptors::Server
    class RequestResponse
      # @param interceptors [Array<GrpcKit::GRPC::ServerInterceptor>]
      def initialize(interceptors)
        @interceptors = interceptors
      end

      # @param call [GrpcKit::Calls::Client::RequestResponse]
      def intercept(request, call, &block)
        if @interceptors && !@interceptors.empty?
          do_intercept(@interceptors.dup, request, call, &block)
        else
          yield(request, call)
        end
      end

      private

      def do_intercept(interceptors, request, call)
        if interceptors.empty?
          return yield(request, call)
        end

        interceptor = interceptors.pop
        interceptor.request_response(request: request, call: call, method: call.method) do
          do_intercept(interceptors, request, call) do |req, c|
            yield(req, c)
          end
        end
      end
    end
  end
end
