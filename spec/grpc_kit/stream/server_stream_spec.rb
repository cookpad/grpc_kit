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
  let(:codec) do
    double(:codec).tap do |c|
      allow(c).to receive(:decode) { |v| v }
      allow(c).to receive(:encode) { |v| v }
    end
  end

  describe '#send_msg' do
    let(:transport) { TestTransport.new }

    context 'when sending a message' do
      context 'in the first time' do
        it do
          server_stream.send_msg(data, codec)
          expect(transport.get_start_response[':status']).to eq('200')
          expect(transport.get_write_data).to eq(data)
          expect(transport.get_end_write).to eq(nil)
          expect(transport.get_write_trailers).to eq(nil)
        end

        context 'and with last' do
          it do
            server_stream.send_msg(data, codec, last: true)
            expect(transport.get_start_response[':status']).to eq('200')
            expect(transport.get_write_data).to eq(data)
            expect(transport.get_end_write).to eq(true)
            expect(transport.get_write_trailers['grpc-status']).to eq(GrpcKit::StatusCodes::OK.to_s)
          end
        end
      end

      context 'in the second time' do
        it do
          server_stream.send_msg(data, codec)
          server_stream.send_msg(data, codec)
          expect(transport.get_start_response[':status']).to eq('200')
          expect(transport.get_write_data).to eq(data + data)
          expect(transport.get_end_write).to eq(nil)
          expect(transport.get_write_trailers).to eq(nil)
        end
      end

      context 'with last' do
        it 'set trailers' do
          server_stream.send_msg(data, codec)
          server_stream.send_msg(data, codec, last: true)
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
      expect(server_stream.recv_msg(codec)).to eq(data)
    end

    context 'when last is given' do
      it 'read data with last' do
        expect(transport).to receive(:read_data).with(last: true).and_return(body)
        expect(server_stream.recv_msg(codec, last: true)).to eq(data)
      end
    end

    context 'when no more data to read' do
      let(:body) { nil }

      it { expect { server_stream.recv_msg(codec) }.to raise_error(StopIteration) }
    end

    context 'when data is larger than limit_size' do
      it { expect { server_stream.recv_msg(codec, limit_size: 2) }.to raise_error(GrpcKit::Errors::ResourceExhausted) }
    end
  end

  describe '#each' do
    let(:body) { [false, data.bytesize, data] }

    before do
      b = [body, nil]
      allow(transport).to receive(:read_data) { b.shift }
    end

    it 'reads data' do
      expect(server_stream.recv_msg(codec)).to eq(data)
      expect { server_stream.recv_msg(codec) }.to raise_error(StopIteration)
    end
  end

  describe '#send_status' do
    let(:transport) { TestTransport.new }

    context 'when it has not sent any data' do
      it 'call submit_headers' do
        server_stream.send_status
        expect(transport.get_submit_headers[':status']).to eq('200')
        expect(transport.get_submit_headers['grpc-status']).to eq(GrpcKit::StatusCodes::OK.to_s)
        expect(transport.get_write_data).to eq(nil)
        expect(transport.get_end_write).to eq(true)
        expect(transport.get_write_trailers).to eq(nil)
      end

      context 'with metadata' do
        it do
          server_stream.send_status(metadata: { 'a' => 'b' })
          expect(transport.get_submit_headers['a']).to eq('b')
        end
      end

      context 'with msg' do
        it do
          server_stream.send_status(msg: 'hello')
          expect(transport.get_submit_headers['grpc-message']).to eq('hello')
        end
      end

      context 'with status' do
        it do
          server_stream.send_status(status: GrpcKit::StatusCodes::UNIMPLEMENTED)
          expect(transport.get_submit_headers['grpc-status']).to eq(GrpcKit::StatusCodes::UNIMPLEMENTED)
        end
      end

      context 'with data' do
        it do
          server_stream.send_status(data: data)
          expect(transport.get_write_data).to eq(data)
          expect(transport.get_start_response[':status']).to eq('200')
          expect(transport.get_write_trailers['grpc-status']).to eq(GrpcKit::StatusCodes::OK)
          expect(transport.get_submit_headers).to eq(nil)
        end
      end
    end

    context 'when it has sent data' do
      before do
        server_stream.send_msg(data, codec)
      end

      it 'call start_response' do
        server_stream.send_status
        expect(transport.get_start_response[':status']).to eq('200')
        expect(transport.get_write_trailers['grpc-status']).to eq(GrpcKit::StatusCodes::OK)
        expect(transport.get_write_data).to eq(data)
        expect(transport.get_end_write).to eq(true)
        expect(transport.get_submit_headers).to eq(nil)
      end

      context 'with metadata' do
        it do
          server_stream.send_status(metadata: { 'a' => 'b' })
          expect(transport.get_submit_headers).to eq(nil)
          expect(transport.get_write_trailers['a']).to eq('b')
        end
      end

      context 'with msg' do
        it do
          server_stream.send_status(msg: 'hello')
          expect(transport.get_submit_headers).to eq(nil)
          expect(transport.get_write_trailers['grpc-message']).to eq('hello')
        end
      end

      context 'with status' do
        it do
          server_stream.send_status(status: GrpcKit::StatusCodes::UNIMPLEMENTED)
          expect(transport.get_submit_headers).to eq(nil)
          expect(transport.get_write_trailers['grpc-status']).to eq(GrpcKit::StatusCodes::UNIMPLEMENTED)
        end
      end

      context 'with data' do
        it do
          server_stream.send_status(data: data)
          expect(transport.get_write_data).to eq(data + data)
          expect(transport.get_start_response[':status']).to eq('200')
          expect(transport.get_write_trailers['grpc-status']).to eq(GrpcKit::StatusCodes::OK)
          expect(transport.get_submit_headers).to eq(nil)
        end
      end
    end
  end
end
