# frozen_string_literal: true

require 'bundler/setup'
require 'grpc_kit'

RSpec.configure do |config|
  config.example_status_persistence_file_path = '.rspec_status'

  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end

  config.before do
    GrpcKit.logger = Logger.new(nil)
  end
end
