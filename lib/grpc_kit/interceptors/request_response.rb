# frozen_string_literal: true

require 'grpc_kit/interceptors/base'

module GrpcKit
  module Interceptors
    module Client
      class RequestResponse < Base
        def intercept(request, ctx, metadata, &block)
          if @interceptors && !@interceptors.empty?
            do_intercept(@interceptors.dup, request, ctx, metadata, &block)
          else
            yield(request, ctx, metadata)
          end
        end

        private

        def do_intercept(interceptors, request, ctx, metadata)
          if interceptors.empty?
            return yield(request, metadata)
          end

          interceptor = interceptors.pop
          interceptor.request_response(request: request, call: ctx, method: ctx.method, metadata: metadata) do
            do_intercept(interceptors, request, ctx, metadata) do |req, c|
              yield(req, c, metadata)
            end
          end
        end
      end
    end

    module Server
      class RequestResponse < Base
        def intercept(request, ctx, &block)
          if @interceptors && !@interceptors.empty?
            do_intercept(@interceptors.dup, request, ctx, &block)
          else
            yield(request, ctx)
          end
        end

        private

        def do_intercept
          if interceptors.empty?
            return yield(request, ctx)
          end

          interceptor = interceptors.pop
          interceptor.request_response(request: request, call: ctx, method: ctx.method) do
            do_intercept(interceptors, request, ctx) do |req, c|
              yield(req, c)
            end
          end
        end
      end
    end
  end
end
