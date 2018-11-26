# frozen_string_literal: true

require 'logger'

module GrpcKit
  module GRPC
    module DefaultLogger
      # @return [Logger]
      def logger
        LOGGER
      end

      LOGGER = Logger.new(STDOUT)
    end

    unless methods.include?(:logger)
      extend DefaultLogger
    end
  end
end
