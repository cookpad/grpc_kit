# frozen_string_literal: true

require 'grpc_kit/server'
require 'support/test_greeter_server'
require 'support/server_helper'
require 'support/test_interceptors'

RSpec.describe 'client_streamer' do
  let(:interceptors) { [] }

  around do |block|
    s = TestGreeterServer.new(client_streamer: call)
    sock = ServerHelper.build_server(s, interceptors: interceptors)
    block.call
    sock.close
  end

  let(:call) do
    lambda do |c|
      3.times do |i|
        expect(c.recv.msg).to eq("message #{i}")
      end

      Hello::Response.new(msg: 'response')
    end
  end

  it 'returns valid response' do
    # expect(call).to receive(:call).once.and_call_original
    stub = Hello::Greeter::Stub.new('localhost', 50051)
    stream = stub.hello_client_streamer({})
    3.times do |i|
      stream.send_msg(Hello::Request.new(msg: "message #{i}"))
    end
    resp = stream.close_and_recv
    expect(resp[0].msg).to eq('response')
  end

  context 'with interceptor' do
    let(:interceptors) { [TestInterceptor.new(client_streamer: client_streamer_interceptor)] }
    let(:client_streamer_interceptor) do
      lambda do |req, call, method, metadata|
        # expect(req.msg).to eq(request)
      end
    end

    it 'returns valid response' do
      expect(call).to receive(:call).once.and_call_original
      expect(client_streamer_interceptor).to receive(:call).once.and_call_original
      stub = Hello::Greeter::Stub.new('localhost', 50051)
      stream = stub.hello_client_streamer({})
      3.times do |i|
        stream.send_msg(Hello::Request.new(msg: "message #{i}"))
      end
      resp = stream.close_and_recv
      expect(resp[0].msg).to eq('response')
    end
  end
end
