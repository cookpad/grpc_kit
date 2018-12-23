# frozen_string_literal: true

require 'timeout'
require 'grpc_kit/errors'
require 'grpc_kit/status_codes'

module GrpcKit
  module Rpcs
    class ClientRpc
      # @return [GrpcKit::MethodConfig]
      attr_reader :config

      # @param config [GrpcKit::MethodConfig]
      def initialize(config)
        @config = config
      end

      def invoke(stream, request, metadata: {}, timeout: nil); end
    end

    class ServerRpc
      # @param handler [GrpcKit::Grpc::GenericService]
      # @param config [GrpcKit::MethodConfig]
      def initialize(handler, config)
        @handler = handler
        @config = config
      end

      def invoke(stream, metadata: {}); end
    end
  end
end
