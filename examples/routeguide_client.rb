# frozen_string_literal: true

$LOAD_PATH.unshift File.expand_path('./examples/routeguide')

require 'grpc_kit'
require 'pry'
require 'json'
require 'logger'
require 'routeguide_services_pb'

RESOURCE_PATH = './examples/routeguide/routeguide.json'

$logger = Logger.new(STDOUT)

def get_feature(stub)
  $logger.info('===== get_feature =====')
  points = [
    Routeguide::Point.new(latitude:  409_146_138, longitude: -746_188_906),
    Routeguide::Point.new(latitude:  0, longitude: 0)
  ]

  points.each do |pt|
    feature = stub.get_feature(pt, metadata: { 'metadata' => 'data1' })
    $logger.info("get_feature #{feature.name}, #{feature.location}")
  end
end

def list_features(stub)
  $logger.info('===== list_features =====')
  rect = Routeguide::Rectangle.new(
    lo: Routeguide::Point.new(latitude: 400_000_000, longitude: -750_000_000),
    hi: Routeguide::Point.new(latitude: 420_000_000, longitude: -730_000_000),
  )

  stream = stub.list_features(rect)

  loop do
    r = stream.recv
    $logger.info("list_features #{r.name} at #{r.location.inspect}")
  end
end

def record_route(stub, size)
  features = File.open(RESOURCE_PATH) do |f|
    JSON.parse(f.read)
  end

  stream = stub.record_route({})

  size.times do
    location = features.sample['location']
    pt = Routeguide::Point.new(latitude: location['latitude'], longitude: location['longitude'])
    puts "- next point is #{pt.inspect}"
    stream.send(pt)
    sleep(rand(0..1))
  end

  resp = stream.close_and_recv
  puts "summary: #{resp.inspect}"
end

opts = {}

if ENV['GRPC_INTERCEPTOR']
  require_relative 'interceptors/client_logging_interceptor'
  opts[:interceptors] = [LoggingInterceptor.new]
elsif ENV['GRPC_TIMEOUT']
  opts[:timeout] = Integer(ENV['GRPC_TIMEOUT'])
end

stub = Routeguide::RouteGuide::Stub.new('localhost', 50051, **opts)

get_feature(stub)
# list_features(stub)
# record_route(stub, 10)
