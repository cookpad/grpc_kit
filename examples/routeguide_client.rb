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

get_feature(stub)
