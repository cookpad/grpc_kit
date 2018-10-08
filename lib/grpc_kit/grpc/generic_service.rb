# frozen_string_literal: true

require 'grpc_kit/grpc/dsl'

module GrpcKit
  module GRPC
    module GenericService
      def self.included(obj)
        obj.extend(GrpcKit::GRPC::Dsl)

        # return unless obj.service_name.nil?
        # if obj.name.nil?
        #   obj.service_name = 'GenericService'
        # else
        # modules = obj.name.split('::')
        # obj.service_name =
        #   if modules.length > 2
        #     modules[modules.length - 2]
        #   else
        #     modules.first
        #   end
        # end
      end
    end
  end
end
