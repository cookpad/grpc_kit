# frozen_string_literal: true

require 'grpc_kit/rpcs/base'
require 'grpc_kit/rpcs/context'

module GrpcKit
  module Rpcs
    module Client
      class RequestResponse < Base
        def invoke(session, request, metadata: {}, timeout: nil, **opts)
          cs = GrpcKit::ClientStream.new(path: @config.path, protobuf: @config.protobuf, session: session)
          context = GrpcKit::Rpcs::Context.new(metadata, @config.method_name, @config.service_name)

          @config.interceptor.intercept(request, context, metadata) do |r, c, m|
            if timeout
              # XXX: when timeout.to_timeout is 0
              Timeout.timeout(timeout.to_timeout, GrpcKit::Errors::DeadlienExceeded) do
                cs.send(r, timeout: timeout.to_s, metadata: m, end_stream: true)
                cs.recv
              end
            else
              cs.send(r, metadata: m, end_stream: true)
              cs.recv
            end
          end
        end
      end
    end

    module Server
      class RequestResponse < Base
        def invoke(stream)
          ss = GrpcKit::ServerStream.new(stream: stream, protobuf: @config.protobuf)
          request = ss.recv(last: true)
          context = GrpcKit::Rpcs::Context.new(stream.headers.metadata, @config.method_name, @config.service_name)
          resp =
            if @config.interceptor
              @config.interceptor.intercept(request, context.freeze) do |req, ctx|
                @handler.send(@config.ruby_style_method_name, req, ctx)
              end
            else
              @handler.send(@config.ruby_style_method_name, request, context.freeze)
            end

          ss.send_msg(resp, last: true)
        end
      end
    end
  end
end
