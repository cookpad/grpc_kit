# frozen_string_literal: true

require 'timeout'

require 'grpc_kit/errors'
require 'grpc_kit/server_stream'
require 'grpc_kit/client_stream'

module GrpcKit
  module Rpcs
    module Client
      Base = Struct.new(
        :path,
        :protobuf,
        :interceptor,
        :service_name,
        :method_name,
      )
    end

    module Server
      Base = Struct.new(
        :handler,
        :method_name,
        :protobuf,
        :path,
        :interceptor,
        :service_name,
      )
    end
  end
end
