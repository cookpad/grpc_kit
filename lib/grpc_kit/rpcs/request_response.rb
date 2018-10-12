# frozen_string_literal: true

require 'grpc_kit/rpcs/base'
require 'grpc_kit/rpcs/context'

module GrpcKit
  module Rpcs
    module Client
      class RequestResponse < Base
        def invoke(session, request, metadata: {}, **opts)
          cs = GrpcKit::ClientStream.new(path: path, protobuf: protobuf, session: session)
          context = GrpcKit::Rpcs::Context.new(metadata, method_name, service_name)
          interceptor.intercept(request, context, metadata) do |r, c, m|
            # TODO: check ctxt's body
            cs.send(r, metadata: m, end_stream: true)
            cs.recv
          end
        end
      end
    end

    module Server
      class RequestResponse < Base
        def invoke(stream)
          ss = GrpcKit::ServerStream.new(stream: stream, protobuf: protobuf)
          request = ss.recv
          context = GrpcKit::Rpcs::Context.new(stream.headers.metadata, method_name, service_name)
          resp =
            if interceptor
              interceptor.intercept(request, context.freeze) do |req, ctx|
                handler.send(method_name, req, ctx)
              end
            else
              handler.send(method_name, request, context.freeze)
            end

          ss.send_msg(resp)
          stream.end_write
        end
      end
    end
  end
end
