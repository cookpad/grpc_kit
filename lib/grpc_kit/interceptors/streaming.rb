# frozen_string_literal: true

module GrpcKit
  module Interceptors
    module Client
      class Streaming
        attr_writer :interceptors

        def initialize
          # Cant' get interceptor at definition time...
          @interceptors = nil
        end

        def intercept(call, metadata, &block)
          if @interceptors && !@interceptors.empty?
            do_intercept(@interceptors.dup, call, metadata, &block)
          else
            yield(call, metadata)
          end
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
        def initialize(interceptors)
          @interceptors = interceptors
        end

        def intercept(call, &block)
          if @interceptors && !@interceptors.empty?
            do_intercept(@interceptors.dup, call, &block)
          else
            yield(call)
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
  end
end
