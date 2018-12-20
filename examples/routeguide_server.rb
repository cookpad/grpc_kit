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
      features = JSON.parse(f.read)
      @features = Hash[features.map { |x| [x['location'], x['name']] }]
    end

    @route_notes = Hash.new { |h, k| h[k] = [] }
  end

  def get_feature(point, ctx)
    GRPC.logger.info('===== get_feature =====')
    name = @features.fetch({ 'longitude' => point.longitude, 'latitude' => point.latitude }, '')
    GRPC.logger.info("Point longitude=#{point.longitude}, latitude=#{point.latitude}, metadata=#{ctx.metadata}")
    Routeguide::Feature.new(location: point, name: name)
  end

  def list_features(rect, stream)
    GRPC.logger.info('===== list_features =====')

    @features.each do |location, name|
      if name.nil? || name == '' || !in_range(location, rect)
        next
      end

      pt = Routeguide::Point.new(location)
      resp = Routeguide::Feature.new(location: pt, name: name)
      GRPC.logger.info(resp)
      stream.send_msg(resp)
    end
  end

  def record_route(stream)
    GRPC.logger.info('===== record_route =====')
    distance = 0
    count = 0
    features = 0
    start_at = Time.now.to_i
    last = nil

    stream.each do |point|
      GRPC.logger.info(point)

      count += 1
      name = @features.fetch({ 'longitude' => point.longitude, 'latitude' => point.latitude }, '')
      unless name == ''
        features += 1
      end

      last = point
      distance += calculate_distance(point, last)
    end

    Routeguide::RouteSummary.new(
      point_count: count,
      feature_count: features,
      distance: distance,
      elapsed_time: Time.now.to_i - start_at,
    )
  end

  def route_chat(call)
    GRPC.logger.info('===== record_chat =====')
    call.each do |rn|
      GRPC.logger.info("route_note location=#{rn.location.inspect}, message=#{rn.message}")
      key = "#{rn.location.latitude} #{rn.location.longitude}"
      saved_msgs = @route_notes[key]
      @route_notes[key] << rn.message

      saved_msgs.each do |m|
        n = Routeguide::RouteNote.new(location: rn.location, message: m)
        call.send_msg(n)
      end
    end
  end

  private

  COORD_FACTOR = 1e7
  RADIUS = 637_100

  def calculate_distance(point_a, point_b)
    lat_a = (point_a.latitude / COORD_FACTOR) * Math::PI / 180
    lat_b = (point_b.latitude / COORD_FACTOR) * Math::PI / 180
    lon_a = (point_a.longitude / COORD_FACTOR) * Math::PI / 180
    lon_b = (point_b.longitude / COORD_FACTOR) * Math::PI / 180

    delta_lat = lat_a - lat_b
    delta_lon = lon_a - lon_b
    a = Math.sin(delta_lat / 2)**2 + Math.cos(lat_a) * Math.cos(lat_b) + Math.sin(delta_lon / 2)**2
    (2 * RADIUS * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a))).to_i
  end

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
opts = {}

if ENV['GRPC_INTERCEPTOR']
  require_relative 'interceptors/server_logging_interceptor'
  opts[:interceptors] = [LoggingInterceptor.new]
end

server = GrpcKit::Server.new(**opts)
server.handle(Server.new)

loop do
  conn = sock.accept
  server.run(conn)
end
