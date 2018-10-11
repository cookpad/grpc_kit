# frozen_string_literal: true

require 'grpc_kit/rpcs/base'

module GrpcKit
  module Rpcs
    module Client
      class BidiStreamer < Base
        def invoke(session, data, opts = {})
        end
      end
    end

    module Server
      class BidiStreamer < Base
      end
    end
  end
end
