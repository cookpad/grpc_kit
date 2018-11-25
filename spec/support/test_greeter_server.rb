# frozen_string_literal: true

require 'grpc_kit'
require_relative 'hello_services_pb'

class TestGreeterServer < Hello::Greeter::Service
  def initialize(request_response: nil, server_streamer: nil, client_streamer: nil, bidi_streamer: nil)
    @request_response = request_response
    @server_streamer = server_streamer
    @client_streamer = client_streamer
    @bidi_streamer = bidi_streamer
  end

  def hello_request_response(req, call)
    @request_response.call(req, call)
  end

  def hello_server_streamer(req, call)
    @server_streamer.call(req, call)
  end

  def hello_client_streamer(call)
    @client_streamer.call(call)
  end

  def hello_bidi_streamer(call)
    @bidi_streamer.call(call)
  end
end
