# frozen_string_literal: true

require 'logger'

require 'grpc_kit/version'
require 'grpc_kit/server'
require 'grpc_kit/client'

module GrpcKit
  class << self
    # @param value [Logger] Any logger
    attr_writer :logger

    # @return [Logger]
    def logger
      @logger ||= Logger.new(STDOUT, level: ENV['GRPC_KIT_LOGLEVEL'] || :info)
    end

    # @param level [String] :debug, :info, :warn, :error, :fatal or :unknown
    # @return [void]
    def self.loglevel=(level)
      logger.level = level
    end
  end
end
