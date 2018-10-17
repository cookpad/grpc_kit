# frozen_string_literal: true

module GrpcKit
  module Interceptors
    module Client
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

    module Server
      class RequestResponse
        def initialize(interceptors)
          @interceptors = interceptors
        end

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
end
