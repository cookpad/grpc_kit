# frozen_string_literal: true

require 'grpc_kit/rpcs/base'

module GrpcKit
  module Rpcs
    module Client
      class ServerStreamer < Base
        def invoke(session, data, opts = {})
          cs = GrpcKit::ClientStream.new(path: path, protobuf: protobuf, session: session)
          cs.send(data, end_stream: true)
          cs
        end
      end
    end

    module Server
      class ServerStreamer < Base
        def invoke(stream)
          ss = GrpcKit::ServerStream.new(stream: stream, protobuf: protobuf)
          req = ss.recv
          handler.send(method_name, req, ss)
          stream.end_write
        end
      end
    end
  end
end
