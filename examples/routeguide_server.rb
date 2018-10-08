# frozen_string_literal: true

$LOAD_PATH.unshift File.expand_path('./examples/routeguide')

require 'grpc_kit'
require 'pry'
require 'json'
require 'routeguide_services_pb'

class Server < Routeguide::RouteGuide::Service
  RESOURCE_PATH = './examples/routeguide/routeguide.json'

  def initialize
    File.open(RESOURCE_PATH) do |f|
      features = JSON.load(f.read)
      @features = Hash[features.map { |x| [x['location'], x['name']] }]
    end
  end

  def get_feature(point, _call)
    name = @features.fetch({ 'longitude' => point.longitude, 'latitude' => point.latitude }, '')
    Routeguide::Feature.new(location: point, name: name)
  end
end

sock = TCPServer.new(50051)

server = GrpcKit::Server.new
server.handle(Server.new)
server.run

loop do
  conn = sock.accept
  server.session_start(conn)
end
