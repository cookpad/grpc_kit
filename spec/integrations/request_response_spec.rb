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
    let(:interceptors) { [TestServerInterceptor.new(request_response: request_response_interceptor)] }
    let(:request_response_interceptor) do
      lambda do |req, call, method|
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

  context 'when timeout is set' do
    let(:call) do
      lambda do |req, _call|
        expect(req.msg).to eq(request)
        sleep 1.5
        Hello::Response.new(msg: response + req.msg)
      end
    end

    it 'raise DeadlineExceeded' do
      stub = Hello::Greeter::Stub.new(ServerHelper.connect)
      expect { stub.hello_request_response(Hello::Request.new(msg: request), timeout: 1) }.to raise_error(GrpcKit::Errors::DeadlineExceeded)
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

  context 'when metada given' do
    let(:interceptors) { [TestServerInterceptor.new(request_response: request_response_interceptor)] }
    let(:metadata) { { 'a' => 'b' } }
    let(:request_response_interceptor) do
      lambda do |req, call, method|
        expect(call.incoming_metadata['a']).to eq('b')
        expect(call.incoming_metadata['c']).to eq('d')
        expect(call.incoming_metadata['d']).to eq('e')
        expect(call.metadata).to eq(call.incoming_metadata)
        expect(req.msg).to eq(request)
        call.outgoing_trailing_metadata['b'] = 'c'
        call.outgoing_initial_metadata['c'] = 'd'
      end
    end

    let(:client_request_response) do
      lambda do |req, call, method, metadata|
        expect(call.metadata['a']).to eq('b')
        expect(call.metadata).to eq(metadata)
        metadata['c'] = 'd'
        call.metadata['d'] = 'e'
      end
    end

    it 'returns valid response' do
      expect(call).to receive(:call).once.and_call_original
      expect(request_response_interceptor).to receive(:call).once.and_call_original
      stub = Hello::Greeter::Stub.new(ServerHelper.connect, interceptors: [TestClientInterceptor.new(request_response: client_request_response)])
      resp = stub.hello_request_response(Hello::Request.new(msg: request), metadata: metadata)
      expect(resp.msg).to eq(response + request)
    end
  end
end
