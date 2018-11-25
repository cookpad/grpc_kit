# frozen_string_literal: true

require 'grpc_kit'

class TestClientInterceptor < GRPC::ClientInterceptor
  def initialize(request_response: nil, server_streamer: nil, client_streamer: nil, bidi_streamer: nil)
    @request_response = request_response
    @server_streamer = server_streamer
    @client_streamer = client_streamer
    @bidi_streamer = bidi_streamer
  end

  def request_response(request: nil, call: nil, method: nil, metadata: nil)
    @request_response.call(request, call, method, metadata)
    yield
  end

  def server_streamer(request: nil, call: nil, method: nil, metadata: nil)
    @server_streamer.call(request, call, method, metadata)
    yield
  end

  def client_streamer(requests: nil, call: nil, method: nil, metadata: nil)
    @client_streamer.call(requests, call, method, metadata)
    yield
  end

  def bidi_streamer(requests: nil, call: nil, method: nil, metadata: nil)
    @bidi_streamer.call(requests, call, method, metadata)
    yield
  end
end

class TestServerInterceptor < GRPC::ServerInterceptor
  def initialize(request_response: nil, server_streamer: nil, client_streamer: nil, bidi_streamer: nil)
    @request_response = request_response
    @server_streamer = server_streamer
    @client_streamer = client_streamer
    @bidi_streamer = bidi_streamer
  end

  def request_response(request: nil, call: nil, method: nil)
    @request_response.call(request, call, method)
    yield
  end

  def server_streamer(request: nil, call: nil, method: nil)
    @server_streamer.call(request, call, method)
    yield
  end

  def client_streamer(call: nil, method: nil)
    @client_streamer.call(call, method)
    yield
  end

  def bidi_streamer(call: nil, method: nil)
    @bidi_streamer.call(call, method)
    yield
  end
end
