# frozen_string_literal: true

require 'timeout'
require 'grpc_kit/errors'
require 'grpc_kit/status_codes'

module GrpcKit
  module Rpcs
    class ClientRpc
      attr_reader :config

      def initialize(config)
        @config = config
      end

      def invoke(stream, request, metadata: {}, timeout: nil); end
    end

    class ServerRpc
      def initialize(handler, config)
        @handler = handler
        @config = config
      end

      def invoke(stream, metadata: {}); end
    end
  end
end
