# frozen_string_literal: true

require 'grpc_kit/rpcs/base'
require 'grpc_kit/rpcs/context'

module GrpcKit
  module Rpcs
    module Client
      class RequestResponse < Base
        def invoke(session, data, opts = {})
          cs = GrpcKit::ClientStream.new(path: path, protobuf: protobuf, session: session)
          cs.send(data, metadata: opts[:metadata], end_stream: true)
          cs.recv
        end
      end
    end

    module Server
      class RequestResponse < Base
        def invoke(stream)
          ss = GrpcKit::ServerStream.new(stream: stream, protobuf: protobuf)
          req = ss.recv
          ctx = GrpcKit::Rpcs::Context.new(stream.headers.metadata)
          resp = handler.send(method_name, req, ctx.freeze)
          ss.send_msg(resp)
          stream.end_write
        end
      end
    end
  end
end
