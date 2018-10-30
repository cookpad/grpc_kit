# frozen_string_literal: true

require 'grpc_kit/rpcs'

module GrpcKit
  module Rpcs::Client
    class BidiStreamer < GrpcKit::Rpcs::ClientRpc
      def invoke(session, data, opts = {}); end
    end
  end
end
