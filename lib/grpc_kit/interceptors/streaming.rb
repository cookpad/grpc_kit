# frozen_string_literal: true

require 'grpc_kit/interceptors/base'

module GrpcKit
  module Interceptors
    module Client
      class Streaming < Base
        def intercept(ctx, &block)
          if @interceptors && !@interceptors.empty?
            do_intercept(@interceptors.dup, ctx, &block)
          else
            yield(ctx)
          end
        end

        private

        def do_intercept(interceptors, call)
          if interceptors.empty?
            return yield(call)
          end

          interceptor = interceptors.pop
          invoke(interceptor, call) do |inter_call|
            do_intercept(interceptors, inter_call) do |c|
              yield(c)
            end
          end
        end
      end
    end

    module Server
      class Streaming < Base
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
          invoke(interceptor, ctx) do |inter_call|
            do_intercept(interceptors, inter_call) do |c|
              yield(c)
            end
          end
        end
      end
    end
  end
end
