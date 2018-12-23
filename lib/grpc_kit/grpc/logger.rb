# frozen_string_literal: true

module GrpcKit
  module Grpc
    module DefaultLogger
      def logger
        GrpcKit.logger
      end
    end

    unless methods.include?(:logger)
      extend DefaultLogger
    end
  end
end
