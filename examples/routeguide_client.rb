# frozen_string_literal: true

$LOAD_PATH.unshift File.expand_path('./examples/routeguide')

require 'grpc_kit'
require 'pry'
require 'routeguide_services_pb'

stub = Routeguide::RouteGuide::Stub.new('localhost', 50051)

def get_feature(stub)
  points = [
    Routeguide::Point.new(latitude:  409_146_138, longitude: -746_188_906),
    Routeguide::Point.new(latitude:  0, longitude: 0)
  ]

  points.each do |pt|
    feature = stub.get_feature(pt)
    puts "get_feature #{feature.name}, #{feature.location}"
  end
end

def list_features(stub)
  rect = Routeguide::Rectangle.new(
    lo: Routeguide::Point.new(latitude: 400_000_000, longitude: -750_000_000),
    hi: Routeguide::Point.new(latitude: 420_000_000, longitude: -730_000_000),
  )

  resps = stub.list_features(rect)
  resps.each do |r|
    p "list_features #{r.name} at #{r.location.inspect}"
  end
end

# get_feature(stub)
list_features(stub)
