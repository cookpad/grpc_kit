# frozen_string_literal: false

require 'grpc_kit'

class TestInterceptor < GRPC::ClientInterceptor
  def initialize(request_response: nil, server_streamer: nil, client_streamer: nil)
    @request_response = request_response
    @server_streamer = server_streamer
    @client_streamer = client_streamer
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
end
