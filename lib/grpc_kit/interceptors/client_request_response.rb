# frozen_string_literal: true

require 'grpc_kit/interceptors'

module GrpcKit
  module Interceptors::Client
    class RequestResponse
      attr_writer :interceptors

      def initialize
        # Cant' get interceptor at definition time...
        @interceptors = nil
      end

      def intercept(request, call, metadata, &block)
        if @interceptors && !@interceptors.empty?
          do_intercept(@interceptors.dup, request, call, metadata, &block)
        else
          yield(request, call, metadata)
        end
      end

      private

      def do_intercept(interceptors, request, call, metadata)
        if interceptors.empty?
          return yield(request, call, metadata)
        end

        interceptor = interceptors.pop
        interceptor.request_response(request: request, call: call, method: call.method, metadata: metadata) do
          do_intercept(interceptors, request, call, metadata) do |r, c, m|
            yield(r, c, m)
          end
        end
      end
    end
  end
end
