# frozen_string_literal: true

require 'grpc_kit/grpc/dsl'

module GrpcKit
  module Grpc
    module GenericService
      def self.included(obj)
        obj.extend(GrpcKit::Grpc::Dsl)
      end
    end
  end
end
