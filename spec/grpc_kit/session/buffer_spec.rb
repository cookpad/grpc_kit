# frozen_string_literal: true

require 'grpc_kit/session/buffer'

RSpec.describe GrpcKit::Session::Buffer do
  let(:buffer) { described_class.new(buffer: buffer_data) }
  let(:buffer_data) { +'' }
  let(:data) { 'buffer data' }

  describe '#write' do
    it 'stores wrote data' do
      expect(buffer.write(data)).to eq(data.bytesize)
      expect(buffer_data).to eq(data)

      expect(buffer.write(data)).to eq(data.bytesize)
      expect(buffer_data).to eq(data + data)
    end

    context 'when buffer is nil' do
      let(:buffer_data) { nil }

      it 'stores wrote data' do
        expect(buffer.write(data)).to eq(data.bytesize)
        expect(buffer.write(data)).to eq(data.bytesize)
      end
    end

    context 'with last is true' do
      it 'set end_write is true' do
        expect(buffer.write(data, last: true)).to eq(data.bytesize)
        expect(buffer.end_write?).to eq(true)
      end
    end
  end

  describe '#read' do
    let(:buffer_data) { super() + data }

    it { expect(buffer.read).to eq(data) }

    context 'when buffer is nil' do
      let(:buffer_data) { nil }
      it { expect(buffer.read).to eq('') }
    end

    context 'when size is given' do
      it { expect(buffer.read(2)).to eq('bu') }
    end

    context 'when size is greater than stored data' do
      it 'returns all stored data' do
        expect(buffer.read(1000)).to eq(data)
      end
    end

    context 'when last is true' do
      it 'set end_read is true' do
        expect(buffer.read(last: true)).to eq(data)
        expect(buffer.end_read?).to eq(true)
      end
    end
  end
end
