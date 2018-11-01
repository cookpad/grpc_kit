# frozen_string_literal: true

lib = File.expand_path('lib', __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'grpc_kit/version'

Gem::Specification.new do |spec|
  spec.name          = 'grpc_kit'
  spec.version       = GrpcKit::VERSION
  spec.authors       = ['ganmacs']
  spec.email         = ['ganmacs@gmail.com']

  spec.summary       = 'A kit for creating gRPC server/client'
  spec.description   = 'A kit for creating gRPC server/client'
  spec.homepage      = 'https://github.com/ganmacs/grpc_kit'
  spec.license       = 'MIT'

  spec.files = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end
  spec.bindir        = 'exe'
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.add_dependency 'ds9', '~> 1.2.1'
  spec.add_dependency 'google-protobuf', '~> 3.6.1'
  spec.add_dependency 'googleapis-common-protos-types', '~> 1.0.2'

  spec.add_development_dependency 'bundler'
  spec.add_development_dependency 'grpc-tools', '~> 1.15.0'
  spec.add_development_dependency 'pry-byebug'
  spec.add_development_dependency 'rake'
  spec.add_development_dependency 'rspec'
  spec.add_development_dependency 'rubocop'
end
