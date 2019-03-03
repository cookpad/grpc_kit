# frozen_string_literal: true

require 'grpc_kit/rpc_dispatcher'
require 'grpc_kit/status_codes'

RSpec.describe GrpcKit::RpcDispatcher do
  let(:dispatcher) do
    described_class.new(rpcs, max: max_value, min: min_value)
  end

  let(:rpcs) do
    { 'method_path' => double(:rpc) }
  end

  let(:max_value) do
    1
  end

  let(:min_value) do
    1
  end

  describe '#schedule' do
    let(:control_queue) { double(:control_queue) }

    context 'when stream has valid path' do
      let(:stream) do
        double(:stream).tap do |s|
          allow(s).to receive_message_chain(:headers, path: 'method_path')
        end
      end

      before do
        allow(GrpcKit::Transport::ServerTransport).to receive(:new).and_return(double(:transport))
      end

      it 'calls #invoke of ServerStream' do
        server_stream = double(:server_stream)
        expect(server_stream).to receive(:invoke).once
        allow(GrpcKit::Stream::ServerStream).to receive(:new).and_return(server_stream)
        dispatcher.schedule([stream, control_queue])
        sleep 1
        dispatcher.shutdown
        until dispatcher.instance_variable_get(:@workers).empty?
          sleep 1
        end
      end
    end

    context 'when the path of stream does not exits' do
      let(:stream) do
        double(:stream).tap do |s|
          allow(s).to receive_message_chain(:headers, path: 'unimplemented_method')
        end
      end

      it 'calls #invoke of ServerStream' do
        server_stream = double(:server_stream)
        expect(server_stream).to receive(:send_status).with(status: GrpcKit::StatusCodes::UNIMPLEMENTED, msg: '[UNIMPLEMENTED] unimplemented_method')
        allow(GrpcKit::Stream::ServerStream).to receive(:new).and_return(server_stream)
        dispatcher.schedule([stream, control_queue])
        sleep 1
        dispatcher.shutdown
        until dispatcher.instance_variable_get(:@workers).empty?
          sleep 1
        end
      end
    end
  end
end
