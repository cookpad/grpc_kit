# frozen_string_literal: true

require 'logger'

require 'grpc_kit/version'
require 'grpc_kit/server'
require 'grpc_kit/client'

module GrpcKit
  def self.logger
    @logger ||= Logger.new(STDOUT, level: :debug) # TODO: use :info level
  end

  def self.logger=(logger)
    @logger = logger
  end
end
