# frozen_string_literal: true

require 'grpc_kit/session/io'

RSpec.describe GrpcKit::Session::IO do
  let(:data) { +'' }
  let(:inner_io) { StringIO.new(data) }
  let(:io) { described_class.new(inner_io) }

  describe '#recv_event' do
    let(:data) { 'io data' }

    it { expect(io.recv_event(data.bytesize)).to eq(data) }

    context 'when given size is greater than io stored' do
      it 'returns all data' do
        expect(io.recv_event(10000)).to eq(data)
      end
    end

    context 'when stored data is EOF' do
      let(:data) { '' }
      it { expect(io.recv_event(1)).to eq(DS9::ERR_EOF) }
    end

    context 'when blocking' do
      before do
        allow(inner_io).to receive(:read_nonblock).and_return(:wait_readable)
      end

      it { expect(io.recv_event(1)).to eq(DS9::ERR_WOULDBLOCK) }
    end
  end

  describe '#send_event' do
    let(:write_data) { 'io data' }

    it 'write data to inner io object' do
      io.send_event(write_data)
      expect(inner_io.string).to eq(write_data)
    end
  end
end
