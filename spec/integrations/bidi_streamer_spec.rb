# frozen_string_literal: true

require 'grpc_kit/server'
require 'support/test_greeter_server'
require 'support/server_helper'
require 'support/test_interceptors'
require 'support/hello2_services_pb'

RSpec.describe 'bidi_streamer' do
  let(:interceptors) { [] }

  around do |block|
    s = TestGreeterServer.new(bidi_streamer: call)
    sock = ServerHelper.build_server(s, interceptors: interceptors)
    block.call
    sock.close
  end

  let(:call) do
    lambda do |c|
      3.times do |i|
        expect(c.recv.msg).to eq("message #{i}")
      end

      3.times do |i|
        c.send_msg(Hello::Response.new(msg: "response #{i}"))
      end
    end
  end

  it 'returns valid response' do
    expect(call).to receive(:call).once.and_call_original
    stub = Hello::Greeter::Stub.new(ServerHelper.connect)
    stream = stub.hello_bidi_streamer({})

    t = Thread.new do
      3.times do |i|
        m = stream.recv
        expect(m.msg).to eq("response #{i}")
      end
    end

    3.times do |i|
      stream.send_msg(Hello::Request.new(msg: "message #{i}"))
    end

    stream.close_and_send
    expect(t.value).to eq(3)
  end

  context 'with interceptor' do
    let(:interceptors) { [TestServerInterceptor.new(bidi_streamer: bidi_streamer_interceptor)] }
    let(:bidi_streamer_interceptor) do
      lambda do |call, method|
      end
    end

    it 'returns valid response' do
      expect(call).to receive(:call).once.and_call_original
      expect(bidi_streamer_interceptor).to receive(:call).once.and_call_original
      stub = Hello::Greeter::Stub.new(ServerHelper.connect)
      stream = stub.hello_bidi_streamer({})

      t = Thread.new do
        3.times do |i|
          m = stream.recv
          expect(m.msg).to eq("response #{i}")
        end
      end

      3.times do |i|
        stream.send_msg(Hello::Request.new(msg: "message #{i}"))
      end

      stream.close_and_send
      expect(t.value).to eq(3)
    end
  end

  context 'when unimplmented method call' do
    it 'raises and unimplmented error' do
      expect(call).not_to receive(:call)
      stub = Hello2::Greeter::Stub.new(ServerHelper.connect)
      stream = stub.hello_bidi_streamer({})
      stream.send_msg(Hello2::Request.new(msg: 'message'))
      expect { stream.recv }.to raise_error(GrpcKit::Errors::Unimplemented)
    end
  end

  context 'when diffirent type argument passed' do
    it 'raises and internal error' do
      expect(call).not_to receive(:call)
      stub = Hello::Greeter::Stub.new(ServerHelper.connect)
      stream = stub.hello_bidi_streamer({})
      expect { stream.send_msg(Hello2::Request.new(msg: 'message')) }.to raise_error(GrpcKit::Errors::Internal)
    end
  end

  context 'when metada given' do
    let(:interceptors) { [TestServerInterceptor.new(bidi_streamer: bidi_streamer_interceptor)] }
    let(:metadata) { { 'a' => 'b' } }
    let(:bidi_streamer_interceptor) do
      lambda do |call, method|
        expect(call.incoming_metadata['a']).to eq('b')
        expect(call.incoming_metadata['c']).to eq('d')
        expect(call.incoming_metadata['d']).to eq('e')
        expect(call.metadata).to eq(call.incoming_metadata)
        call.outgoing_trailing_metadata['b'] = 'c'
        call.outgoing_initial_metadata['c'] = 'd'
      end
    end

    let(:client_bidi_streamer) do
      lambda do |req, call, method, metadata|
        expect(call.metadata['a']).to eq('b')
        expect(call.metadata).to eq(metadata)

        metadata['c'] = 'd'
        call.metadata['d'] = 'e'
      end
    end

    it 'returns valid response' do
      expect(call).to receive(:call).once.and_call_original
      expect(bidi_streamer_interceptor).to receive(:call).once.and_call_original
      stub = Hello::Greeter::Stub.new(ServerHelper.connect, interceptors: [TestClientInterceptor.new(bidi_streamer: client_bidi_streamer)])
      stream = stub.hello_bidi_streamer({}, metadata: { 'a' => 'b' })

      t = Thread.new do
        3.times do |i|
          m = stream.recv
          expect(m.msg).to eq("response #{i}")
        end
      end

      3.times do |i|
        stream.send_msg(Hello::Request.new(msg: "message #{i}"))
      end

      stream.close_and_send
      expect(t.value).to eq(3)
    end
  end
end
