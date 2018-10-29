# frozen_string_literal: true

require 'grpc_kit/server'
require 'support/test_greeter_server'
require 'support/server_helper'
require 'support/test_interceptors'

RSpec.describe 'request_response' do
  let(:request) { 'request_name' }
  let(:response) { 'response_name' }
  let(:interceptors) { [] }

  around do |block|
    s = TestGreeterServer.new(request_response: call)
    sock = ServerHelper.build_server(s, interceptors: interceptors)
    block.call
    sock.close
  end

  let(:call) do
    lambda do |req, _call|
      expect(req.msg).to eq(request)
      Hello::Response.new(msg: response + req.msg)
    end
  end

  it 'returns valid response' do
    expect(call).to receive(:call).once.and_call_original
    stub = Hello::Greeter::Stub.new('localhost', 50051)
    resp = stub.hello_request_response(Hello::Request.new(msg: request))
    expect(resp.msg).to eq(response + request)
  end

  context 'with interceptor' do
    let(:interceptors) { [TestInterceptor.new(request_response: request_response_interceptor)] }
    let(:request_response_interceptor) do
      lambda do |req, call, method, metadata|
        expect(req.msg).to eq(request)
      end
    end

    it 'returns valid response' do
      expect(call).to receive(:call).once.and_call_original
      expect(request_response_interceptor).to receive(:call).once.and_call_original
      stub = Hello::Greeter::Stub.new('localhost', 50051)
      resp = stub.hello_request_response(Hello::Request.new(msg: request))
      expect(resp.msg).to eq(response + request)
    end
  end
end
