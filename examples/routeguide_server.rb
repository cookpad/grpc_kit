# frozen_string_literal: true

$LOAD_PATH.unshift File.expand_path('./examples/routeguide')

require 'grpc_kit'
require 'pry'
require 'json'
require 'routeguide_services_pb'
require 'logger'

class Server < Routeguide::RouteGuide::Service
  RESOURCE_PATH = './examples/routeguide/routeguide.json'

  def initialize
    @logger = Logger.new(STDOUT)
    File.open(RESOURCE_PATH) do |f|
      features = JSON.parse(f.read)
      @features = Hash[features.map { |x| [x['location'], x['name']] }]
    end
  end

  def get_feature(point, _call)
    name = @features.fetch({ 'longitude' => point.longitude, 'latitude' => point.latitude }, '')
    Routeguide::Feature.new(location: point, name: name)
  end

  def list_features(rect, stream)
    @logger.info('===== list_features =====')

    @features.each do |location, name|
      if name.nil? || name == '' || !in_range(location, rect)
        next
      end

      pt = Routeguide::Point.new(location)
      resp = Routeguide::Feature.new(location: pt, name: name)
      @logger.info(Routeguide::Feature.new(location: pt, name: name))
      stream.send_msg(resp)
    end
  end

  private

  def in_range(point, rect)
    longitudes = [rect.lo.longitude, rect.hi.longitude]
    left = longitudes.min
    right = longitudes.max

    latitudes = [rect.lo.latitude, rect.hi.latitude]
    bottom = latitudes.min
    top = latitudes.max
    (point['longitude'] >= left) && (point['longitude'] <= right) && (point['latitude'] >= bottom) && (point['latitude'] <= top)
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
