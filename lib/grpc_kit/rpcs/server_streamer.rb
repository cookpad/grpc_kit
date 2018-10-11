# frozen_string_literal: true

require 'grpc_kit/server_stream'
require 'grpc_kit/client_stream'

module GrpcKit
  module Rpcs
    module Client
      class ServerStreamer
        def initialize(path:, protobuf:, opts: {})
          @path = path
          @protobuf = protobuf
          @opts = opts
        end

        def invoke(session, data)
          cs = GrpcKit::ClientStream.new(path: @path, protobuf: @protobuf, session: session)
          cs.send(data, end_stream: true)
          cs
        end
      end
    end

    module Server
      class ServerStreamer
        def initialize(handler:, method_name:, protobuf:)
          @handler = handler
          @method_name = method_name
          @protobuf = protobuf
        end

        def invoke(stream)
          ss = GrpcKit::ServerStream.new(stream: stream, protobuf: @protobuf)
          req = ss.recv
          @handler.send(@method_name, req, ss)
          stream.end_write
        end
      end
    end
  end
end
