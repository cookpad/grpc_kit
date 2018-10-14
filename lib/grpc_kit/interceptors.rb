# frozen_string_literal: true

module GrpcKit
  module Interceptors
    module Server
      class RequestResponse
        def initialize(interceptors)
          @interceptors = interceptors
        end

        def intercept(request, ctx, &block)
          if @interceptors && !@interceptors.empty?
            do_intercept(@interceptors.dup, request, ctx, &block)
          else
            yield(request, ctx)
          end
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

      class ServerStreamer
        def initialize(interceptors)
          @interceptors = interceptors
        end

        def intercept(ctx, &block)
          if @interceptors && !@interceptors.empty?
            do_intercept(@interceptors.dup, ctx, &block)
          else
            yield(ctx)
          end
        end

        private

        def do_intercept(interceptors, ctx)
          if interceptors.empty?
            return yield(ctx)
          end

          interceptor = interceptors.pop
          # We don't need a `:request` parameter but,
          # it shuoldn't remove from paramters due to having a compatibility of grpc gem.
          interceptor.server_streamer(request: nil, call: ctx, method: ctx.method) do |ss|
            do_intercept(interceptors, ss) do |c|
              yield(c)
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

      class ServerStreamer
        attr_writer :interceptors # XXX?

        def intercept(ctx, &block)
          if @interceptors && !@interceptors.empty?
            do_intercept(@interceptors.dup, ctx, &block)
          else
            yield(ctx)
          end
        end

        private

        def do_intercept(interceptors, ctx)
          if interceptors.empty?
            return yield(ctx)
          end

          interceptor = interceptors.pop
          # We don't need a `:request` parameter but,
          # it shuoldn't remove from paramters due to having a compatibility of grpc gem.
          interceptor.server_streamer(request: nil, call: ctx, method: ctx.method) do |ss|
            do_intercept(interceptors, ss) do |c|
              yield(c)
            end
          end
        end
      end
    end
  end
end
