# frozen_string_literal: true

require 'grpc_kit/server_stream'
require 'grpc_kit/client_stream'

module GrpcKit
  module Rpcs
    module Client
      Base = Struct.new(:path, :protobuf)
    end

    module Server
      Base = Struct.new(:handler, :method_name, :protobuf)
    end
  end
end
