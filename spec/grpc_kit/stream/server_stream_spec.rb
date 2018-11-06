# frozen_string_literal: true

require 'grpc_kit/transport/packable'
require 'grpc_kit/stream/server_stream'
require 'support/test_transport'

RSpec.describe GrpcKit::Stream::ServerStream do
  let(:server_stream) { described_class.new(transport) }
  let(:transport) { double(:transport) }
  let(:data) { 'hello world' }
  let(:config) do
    double(
      :config,
      max_receive_message_size: 1000,
    )
  end
  let(:protobuf) do
    double(:protobuf).tap do |pb |
      allow(pb).to receive(:decode) { |v| v }
      allow(pb).to receive(:encode) { |v| v }
    end
  end

  describe '#send_msg' do
    let(:transport) { TestTransport.new }

    context 'when sending a message' do
      context 'in the first time' do
        it do
          server_stream.send_msg(data, protobuf)
          expect(transport.get_start_response[':status']).to eq('200')
          expect(transport.get_write_data).to eq(data)
          expect(transport.get_write_trailers).to eq(nil)
        end

        context 'and with last' do
          it do
            server_stream.send_msg(data, protobuf, last: true)
            expect(transport.get_start_response[':status']).to eq('200')
            expect(transport.get_write_data).to eq(data)
            expect(transport.get_write_trailers['grpc-status']).to eq(GrpcKit::StatusCodes::OK.to_s)
          end
        end
      end

      context 'in the second time' do
        it do
          server_stream.send_msg(data, protobuf)
          server_stream.send_msg(data, protobuf)
          expect(transport.get_start_response[':status']).to eq('200')
          expect(transport.get_write_data).to eq(data + data)
          expect(transport.get_write_trailers).to eq(nil)
        end
      end

      context 'with last' do
        it 'set trailers' do
          server_stream.send_msg(data, protobuf)
          server_stream.send_msg(data, protobuf, last: true)
          expect(transport.get_start_response[':status']).to eq('200')
          expect(transport.get_write_data).to eq(data + data)
          expect(transport.get_write_trailers['grpc-status']).to eq(GrpcKit::StatusCodes::OK.to_s)
        end
      end
    end
  end

  describe '#recv_msg' do
    let(:body) { [false, data.bytesize, data] }

    before do
      allow(transport).to receive(:read_data).and_return(body)
    end

    it 'reads data' do
      expect(server_stream.recv_msg(protobuf)).to eq(data)
    end

    context 'when last is given' do
      it 'read data with last' do
        expect(transport).to receive(:read_data).with(last: true).and_return(body)
        expect(server_stream.recv_msg(protobuf, last: true)).to eq(data)
      end
    end

    context 'when no more data to read' do
      let(:body) { nil }

      it { expect { server_stream.recv_msg(protobuf) }.to raise_error(StopIteration) }
    end

    context 'when data is larger than limit_size' do
      it { expect { server_stream.recv_msg(protobuf, limit_size: 2) }.to raise_error(GrpcKit::Errors::ResourceExhausted) }
    end
  end

  describe '#each' do
    let(:body) { [false, data.bytesize, data] }

    before do
      b = [body, nil]
      allow(transport).to receive(:read_data) { b.shift }
    end

    it 'reads data' do
      expect(server_stream.recv_msg(protobuf)).to eq(data)
      expect { server_stream.recv_msg(protobuf) }.to raise_error(StopIteration)
    end
  end
end
