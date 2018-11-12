# frozen_string_literal: true

require 'grpc_kit/transport/packable'

RSpec.describe GrpcKit::Session::SendBuffer do
  let(:buffer) { described_class.new }

  describe '#write' do
    it 'writes data to inner buffer' do
      buffer.write('abc')

      expect(buffer.instance_variable_get(:@buffer)).to eq('abc')
    end

    context 'when last is true' do
      it 'check end_write true' do
        buffer.write('a', last: true)
        expect(buffer).to be_end_write
      end
    end
  end

  describe '#end_write' do
    it 'check end_write true' do
      buffer.end_write
      expect(buffer).to be_end_write
    end
  end

  describe '#read' do
    it 'read stored data' do
      buffer.write('abcd')
      expect(buffer.read(10)).to eq('abcd')
    end

    context 'when no one wrote data yet' do
      it { expect(buffer.read(10)).to eq(DS9::ERR_DEFERRED) }
    end

    context 'when stored data is nothing' do
      it 'return false' do
        buffer.write('abcd')
        expect(buffer.read(10)).to eq('abcd')
        expect(buffer.read(10)).to eq(DS9::ERR_DEFERRED)
      end

      context 'when end_write is true' do
        it 'return nil' do
          buffer.write('abcd', last: true)
          expect(buffer.read(10)).to eq('abcd')
          expect(buffer.read(10)).to eq(nil)
        end
      end
    end
  end
end
