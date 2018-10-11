# frozen_string_literal: true

require 'grpc_kit/server_stream'
require 'grpc_kit/client_stream'

module GrpcKit
  module Rpcs
    module Client
      class ClientStreamer
        attr_writer :session

        def initialize(path:, protobuf:, opts: {})
          @path = path
          @protobuf = protobuf
          @opts = opts
        end

        def invoke(session, _data)
          GrpcKit::ClientStream.new(path: @path, protobuf: @protobuf, session: session)
        end
      end
    end

    module Server
      class ClientStreamer
        def initialize(handler:, method_name:, protobuf:)
          @handler = handler
          @method_name = method_name
          @protobuf = protobuf
        end

        def invoke(stream)
          ss = GrpcKit::ServerStream.new(stream: stream, protobuf: @protobuf)
          resp = @handler.send(@method_name, ss)
          ss.send_msg(resp)
          stream.end_write
        end
      end
    end
  end
end
