# frozen_string_literal: true

require 'grpc_kit/server'
require 'support/test_greeter_server'
require 'support/server_helper'
require 'support/test_interceptors'
require 'support/hello2_services_pb'

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
    stub = Hello::Greeter::Stub.new(ServerHelper.connect)
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
      stub = Hello::Greeter::Stub.new(ServerHelper.connect)
      resp = stub.hello_request_response(Hello::Request.new(msg: request))
      expect(resp.msg).to eq(response + request)
    end
  end

  context 'when unimplmented method call' do
    it 'raises and unimplmented error' do
      expect(call).not_to receive(:call)
      stub = Hello2::Greeter::Stub.new(ServerHelper.connect)
      expect { stub.hello_request_response(Hello2::Request.new(msg: 'message')) }.to raise_error(GrpcKit::Errors::Unimplemented)
    end
  end

  context 'when diffirent type argument passed' do
    it 'raises an internal error' do
      expect(call).not_to receive(:call)
      stub = Hello::Greeter::Stub.new(ServerHelper.connect)
      expect { stub.hello_request_response(Hello2::Request.new(msg: 'message')) }.to raise_error(GrpcKit::Errors::Internal)
    end
  end
end
