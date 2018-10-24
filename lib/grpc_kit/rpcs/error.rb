# frozen_string_literal: true

require 'grpc_kit/status_codes'

module GrpcKit
  module Rpcs
    module Client
      class Error
        # def invoke(session, request, authority:, error)
        # end
      end
    end

    module Server
      class Error
        def send_bad_status(stream, session, bad_status)
          ss = GrpcKit::Streams::Server.new(stream: stream, protobuf: nil, session: session)
          ss.send_status(status: bad_status.code, msg: bad_status.grpc_message)
        end
      end
    end
  end
end
