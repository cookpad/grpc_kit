# frozen_string_literal: true

require 'grpc_kit/transport/packable'
require 'grpc_kit/stream/client_stream'

RSpec.describe GrpcKit::Stream::ClientStream do
  let(:client_stream) { described_class.new(transport, config, authority: authority) }
  let(:authority) { 'localhost:50051' }
  let(:transport) { double(:transport) }
  let(:config) do
    double(
      :config,
      max_receive_message_size: 1000,
      codec: codec,
    )
  end

  let(:codec) do
    c = double(:codec)
    allow(c).to receive(:decode) { |v| v }
    c
  end

  describe '#recv_msg' do
    let(:data) { 'hello world' }
    let(:body) { [false, data.bytesize, data] }

    before do
      allow(transport).to receive(:read_data).and_return(body)
      client_stream.instance_variable_set(:@started, true)
    end

    it 'reads data' do
      expect(client_stream).not_to receive(:check_status!)
      expect(client_stream.recv_msg).to eq(data)
    end

    context 'when last is given' do
      it 'read data and call check_status!' do
        expect(client_stream).to receive(:check_status!).once
        expect(client_stream.recv_msg(last: true)).to eq(data)
      end
    end

    context 'when no more data to read' do
      let(:body) { nil }

      it 'call check_status! and raise StopIteration' do
        expect(client_stream).to receive(:check_status!).once
        expect { client_stream.recv_msg }.to raise_error(StopIteration)
      end
    end

    context 'when stream never send a request' do
      before do
        client_stream.instance_variable_set(:@started, false)
      end

      it { expect { client_stream.recv_msg }.to raise_error(StandardError) }
    end
  end

  describe '#close_and_recv' do
    let(:data) { 'hello world' }
    let(:body) { [false, data.bytesize, data] }

    before do
      allow(transport).to receive(:close_and_flush).once
      v = [body, nil]
      allow(transport).to receive(:read_data) { v.shift }
      client_stream.instance_variable_set(:@started, true)
    end

    it 'read data until no data' do
      expect(client_stream).to receive(:check_status!).once
      expect(client_stream.close_and_recv).to eq(data)
    end
  end
end
