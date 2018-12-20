# frozen_string_literal: true

require 'grpc_kit/server'
require 'support/test_greeter_server'
require 'support/server_helper'
require 'support/test_interceptors'

RSpec.describe 'server_streamer' do
  let(:request) { 'request_name' }
  let(:response) { 'response_name' }
  let(:interceptors) { [] }

  around do |block|
    s = TestGreeterServer.new(server_streamer: call)
    sock = ServerHelper.build_server(s, interceptors: interceptors)
    block.call
    sock.close
  end

  let(:call) do
    lambda do |req, call|
      expect(req.msg).to eq(request)
      3.times do |i|
        call.send_msg(Hello::Response.new(msg: "message #{i}"))
      end
    end
  end

  it 'returns valid response' do
    expect(call).to receive(:call).once.and_call_original
    stub = Hello::Greeter::Stub.new(ServerHelper.connect)
    stream = stub.hello_server_streamer(Hello::Request.new(msg: request))
    3.times do |i|
      expect(stream.recv.msg).to eq("message #{i}")
    end
  end

  context 'with interceptor' do
    let(:interceptors) { [TestServerInterceptor.new(server_streamer: server_streamer_interceptor)] }
    let(:server_streamer_interceptor) do
      lambda do |req, call, method|
      end
    end

    it 'returns valid response' do
      expect(call).to receive(:call).once.and_call_original
      expect(server_streamer_interceptor).to receive(:call).once.and_call_original
      stub = Hello::Greeter::Stub.new(ServerHelper.connect)
      stream = stub.hello_server_streamer(Hello::Request.new(msg: request))
      3.times do |i|
        expect(stream.recv.msg).to eq("message #{i}")
      end
    end
  end

  context 'when timeout is set' do
    let(:call) do
      lambda do |req, call|
        expect(req.msg).to eq(request)
        sleep 2
        call.send_msg(Hello::Response.new(msg: 'message'))
      end
    end

    it 'raise DeadlineExceeded' do
      stub = Hello::Greeter::Stub.new(ServerHelper.connect)
      stream = stub.hello_server_streamer(Hello::Request.new(msg: request), timeout: 1)

      expect { stream.recv }.to raise_error(GrpcKit::Errors::DeadlineExceeded)
    end
  end

  context 'when unimplmented method call' do
    it 'raises and unimplmented error' do
      expect(call).not_to receive(:call)
      stub = Hello2::Greeter::Stub.new(ServerHelper.connect)
      stream = stub.hello_server_streamer(Hello2::Request.new(msg: request))
      expect { stream.recv }.to raise_error(GrpcKit::Errors::Unimplemented)
    end
  end

  context 'when diffirent type argument passed' do
    it 'raises an internal error' do
      expect(call).not_to receive(:call)
      stub = Hello::Greeter::Stub.new(ServerHelper.connect)
      expect { stub.hello_server_streamer(Hello2::Request.new(msg: request)) }.to raise_error(GrpcKit::Errors::Internal)
    end
  end

  context 'when metada given' do
    let(:interceptors) { [TestServerInterceptor.new(server_streamer: server_streamer_interceptor)] }
    let(:metadata) { { 'a' => 'b' } }
    let(:server_streamer_interceptor) do
      lambda do |req, call, method|
        expect(call.incoming_metadata['a']).to eq('b')
        expect(call.incoming_metadata['c']).to eq('d')
        expect(call.incoming_metadata['d']).to eq('e')
        expect(call.metadata).to eq(call.incoming_metadata)
        call.outgoing_trailing_metadata['b'] = 'c'
        call.outgoing_initial_metadata['c'] = 'd'
      end
    end

    let(:client_server_streamer) do
      lambda do |req, call, method, metadata|
        expect(call.metadata['a']).to eq('b')
        expect(call.metadata).to eq(metadata)

        metadata['c'] = 'd'
        call.metadata['d'] = 'e'
      end
    end

    it 'returns valid response' do
      expect(call).to receive(:call).once.and_call_original
      expect(server_streamer_interceptor).to receive(:call).once.and_call_original
      stub = Hello::Greeter::Stub.new(ServerHelper.connect, interceptors: [TestClientInterceptor.new(server_streamer: client_server_streamer)])
      stream = stub.hello_server_streamer(Hello::Request.new(msg: request), metadata: { 'a' => 'b' })
      3.times do |i|
        expect(stream.recv.msg).to eq("message #{i}")
      end
    end
  end
end
