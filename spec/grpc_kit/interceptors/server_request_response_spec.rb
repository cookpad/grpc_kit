# frozen_string_literal: true

require 'grpc_kit/grpc/interceptor'
require 'grpc_kit/interceptors/server_request_response'

RSpec.describe GrpcKit::Interceptors::Server::RequestResponse do
  let(:interceptor) { described_class.new(interceptors) }
  let(:interceptors) { [interceptor1, interceptor2] }
  let(:request) { double(:request) }
  let(:method) { double(:method) }
  let(:call) { double(:call, method: method) }
  let(:queue) { [] }

  let(:interceptor1) do
    Class.new(GrpcKit::Grpc::ClientInterceptor) do
      def initialize(queue)
        @queue = queue
      end

      def request_response(*)
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

      def request_response(*)
        @queue.push(:interceptor2)
        yield
      end
    end.new(queue)
  end

  it "call all interceptors's request_response" do
    expect(interceptor1).to receive(:request_response).with(request: request, call: call, method: method).once.and_call_original
    expect(interceptor2).to receive(:request_response).with(request: request, call: call, method: method).once.and_call_original

    ret = interceptor.intercept(request, call) do
      'response'
    end
    expect(ret).to eq('response')
    expect(queue).to eq(%i[interceptor2 interceptor1])
  end

  context 'when given interceptor is empty' do
    let(:interceptors) { [] }

    it 'raises an Argument error' do
      expect(interceptor1).not_to receive(:request_response)
      expect(interceptor2).not_to receive(:request_response)

      expect { interceptor.intercept(call) {} }.to raise_error(ArgumentError)
    end
  end
end
