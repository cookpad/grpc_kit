# frozen_string_literal: true

require 'grpc_kit/rpcs/base'

module GrpcKit
  module Rpcs
    module Client
      class ClientStreamer < Base
        def invoke(session, _data, opts = {})
          GrpcKit::ClientStream.new(path: path, protobuf: protobuf, session: session)
        end
      end
    end

    module Server
      class ClientStreamer < Base
        def invoke(stream)
          ss = GrpcKit::ServerStream.new(stream: stream, protobuf: protobuf)
          resp = handler.send(method_name, ss)
          ss.send_msg(resp)
          stream.end_write
        end
      end
    end
  end
end
