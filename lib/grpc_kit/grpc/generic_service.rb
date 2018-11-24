# frozen_string_literal: true

require 'grpc_kit/grpc/dsl'

module GrpcKit
  module GRPC
    module GenericService
      def self.included(obj)
        obj.extend(GrpcKit::GRPC::Dsl)
      end
    end
  end
end
