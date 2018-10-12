# frozen_string_literal: true

module GrpcKit
  module Interceptors
    module Server
      class RequestResponse
        def initialize(interceptors)
          @interceptors = interceptors
        end

        def intercept(request, ctx, &block)
          do_intercept(@interceptors.dup, request, ctx, &block)
        end

        private

        def do_intercept(interceptors, request, ctx)
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

    module Client
      class RequestResponse
        attr_writer :interceptors # XXX?

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
  end
end
