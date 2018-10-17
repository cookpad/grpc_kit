# frozen_string_literal: true

require 'timeout'

require 'grpc_kit/errors'
require 'grpc_kit/rpcs/call'
require 'grpc_kit/streams/server'
require 'grpc_kit/streams/client'

module GrpcKit
  module Rpcs
    module Client
      class Base
        attr_reader :config
        def initialize(config)
          @config = config
        end
      end
    end

    module Server
      class Base
        def initialize(handler, config)
          @handler = handler
          @config = config
        end
      end
    end
  end
end
