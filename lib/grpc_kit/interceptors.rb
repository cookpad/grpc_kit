# frozen_string_literal: true

require 'grpc_kit/interceptor_registory'

module GrpcKit
  module Interceptors
    module Client
      class Streaming
        # @param interceptors [Array<GrpcKit::Grpc::ClientInterceptor>]
        def initialize(interceptors)
          @registry = GrpcKit::InterceptorRegistry.new(interceptors)
        end

        # @param metadata [Hash<String,String>]
        def intercept(call, metadata, &block)
          do_intercept(@registry.build, call, metadata, &block)
        end

        private

        def do_intercept(interceptors, call, metadata)
          if interceptors.empty?
            return yield(call, metadata)
          end

          interceptor = interceptors.pop
          invoke(interceptor, call, metadata) do |inter_call, meta|
            do_intercept(interceptors, inter_call, meta) do |c, m|
              yield(c, m)
            end
          end
        end
      end
    end

    module Server
      class Streaming
        # @param interceptors [Array<GrpcKit::Grpc::ServerInterceptor>]
        def initialize(interceptors)
          @registry = GrpcKit::InterceptorRegistry.new(interceptors)
        end

        def intercept(call, &block)
          do_intercept(@registry.build, call, &block)
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
  end
end
