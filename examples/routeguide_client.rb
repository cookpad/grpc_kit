# frozen_string_literal: true

# rubocop:disable Style/GlobalVars

$LOAD_PATH.unshift File.expand_path('./examples/routeguide')

require 'grpc_kit'
require 'pry'
require 'json'
require 'logger'
require 'routeguide_services_pb'

RESOURCE_PATH = './examples/routeguide/routeguide.json'
HOST = 'localhost'
PORT = 50051

$logger = Logger.new(STDOUT)

def get_feature(stub)
  $logger.info('===== get_feature =====')
  points = [
    Routeguide::Point.new(latitude:  409_146_138, longitude: -746_188_906),
    Routeguide::Point.new(latitude:  0, longitude: 0)
  ]

  points.each do |pt|
    feature = stub.get_feature(pt)
    if feature.name == ''
      $logger.info("Found nothing at #{feature.inspect}")
    else
      $logger.info("Found '#{feature.name}' at #{feature.location.inspect}")
    end
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
    $logger.info("Found #{r.name} at #{r.location.inspect}")
  end
end

def record_route(stub, size)
  $logger.info('===== record_route =====')

  features = File.open(RESOURCE_PATH) do |f|
    JSON.parse(f.read)
  end

  stream = stub.record_route({})

  size.times do
    location = features.sample['location']
    point = Routeguide::Point.new(latitude: location['latitude'], longitude: location['longitude'])
    puts "Next point is #{point.inspect}"
    stream.send_msg(point)
    sleep(rand(0..1))
  end

  resp = stream.close_and_recv
  puts "summary: #{resp[0].inspect}"
end

ROUTE_CHAT_NOTES = [
  Routeguide::RouteNote.new(message: 'First message', location: Routeguide::Point.new(latitude: 0, longitude: 1)),
  Routeguide::RouteNote.new(message: 'Second message', location: Routeguide::Point.new(latitude: 0, longitude: 2)),
  Routeguide::RouteNote.new(message: 'Third message', location: Routeguide::Point.new(latitude: 0, longitude: 3)),
  Routeguide::RouteNote.new(message: 'Fifth message', location: Routeguide::Point.new(latitude: 0, longitude: 1)),
  Routeguide::RouteNote.new(message: 'Fifth message', location: Routeguide::Point.new(latitude: 0, longitude: 2)),
  Routeguide::RouteNote.new(message: 'Sixth message', location: Routeguide::Point.new(latitude: 0, longitude: 3)),
].freeze

def route_chat(stub)
  $logger.info('===== route_chat =====')

  call = stub.route_chat({})

  # t = Thread.new do
  #   loop do
  #     begin
  #       rn = call.recv
  #     rescue => e
  #       retry
  #     end
  #     $logger.info("Got message #{rn.message} at point point(#{rn.location.latitude}, #{rn.location.longitude})")
  #   end
  # end

  # thread?
  ROUTE_CHAT_NOTES.each do |rcn|
    call.send_msg(rcn)
    sleep 1

    # multiple call...
  end

  puts nil, '<============================================================ OUTPUT START HERE'
  call.close_and_send
  puts '<============================================================ OUTPUT CLOSE HERE', nil
  t.join
end

opts = {}

if ENV['GRPC_INTERCEPTOR']
  require_relative 'interceptors/client_logging_interceptor'
  opts[:interceptors] = [LoggingInterceptor.new]
elsif ENV['GRPC_TIMEOUT']
  opts[:timeout] = Integer(ENV['GRPC_TIMEOUT'])
end

sock = TCPSocket.new(HOST, PORT)
stub = Routeguide::RouteGuide::Stub.new(sock, **opts)

# get_feature(stub)
# list_features(stub)
# record_route(stub, 10)
route_chat(stub)

# rubocop:enable Style/GlobalVars
