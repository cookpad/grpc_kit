# frozen_string_literal: true

require 'logger'

require 'grpc_kit/version'
require 'grpc_kit/server'
require 'grpc_kit/client'

module GrpcKit
  class << self
    attr_writer :logger

    def logger
      @logger ||= Logger.new(STDOUT, level: ENV['GRPC_KIT_LOGLEVEL'] || :info)
    end

    # @param level [String] :debug, :info, :warn, :error, :fatal or :unknown
    def self.loglevel=(level)
      logger.level = level
    end
  end
end
