# frozen_string_literal: true

require 'grpc_kit/grpc/interceptor'
require 'grpc_kit/interceptors/server_client_streamer'

RSpec.describe GrpcKit::Interceptors::Server::ClientStreamer do
  let(:interceptor) { described_class.new(interceptors) }
  let(:interceptors) { [interceptor1, interceptor2] }
  let(:method) { double(:method) }
  let(:call) { double(:call, method: method) }
  let(:queue) { [] }

  let(:interceptor1) do
    Class.new(GrpcKit::Grpc::ClientInterceptor) do
      def initialize(queue)
        @queue = queue
      end

      def client_streamer(*)
        @queue.push(:interceptor1)
        yield
      end
    end.new(queue)
  end

  let(:interceptor2) do
    Class.new(GrpcKit::Grpc::ClientInterceptor) do
      def initialize(queue)
        @queue = queue
      end

      def client_streamer(*)
        @queue.push(:interceptor2)
        yield
      end
    end.new(queue)
  end

  it "call all interceptors's client_streamer" do
    expect(interceptor1).to receive(:client_streamer).with(call: call, method: method).once.and_call_original
    expect(interceptor2).to receive(:client_streamer).with(call: call, method: method).once.and_call_original

    ret = interceptor.intercept(call) do |c|
      [c].tap { |rv| expect(rv).to eq([call]) }
    end
    expect(ret).to eq([call])
    expect(queue).to eq(%i[interceptor2 interceptor1])
  end

  context 'when given interceptor is empty' do
    let(:interceptors) { [] }

    it 'raises an Argument error' do
      expect(interceptor1).not_to receive(:client_streamer)
      expect(interceptor2).not_to receive(:client_streamer)

      expect { interceptor.intercept(call) {} }.to raise_error(ArgumentError)
    end
  end
end
