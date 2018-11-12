# frozen_string_literal: true

require 'grpc_kit/session/recv_buffer'

RSpec.describe GrpcKit::Session::RecvBuffer do
  let(:buffer) { described_class.new }

  describe '#write' do
    it 'writes data' do
      buffer.write('abc')
      expect(buffer.instance_variable_get(:@buffer)).to eq('abc')
    end
  end

  describe '#end_read' do
    it 'check end_write true' do
      buffer.end_read
      expect(buffer).to be_end_read
    end
  end

  describe '#read' do
    context 'when stored data exists' do
      before do
        buffer.write('abcd')
      end

      it { expect(buffer.read).to eq('abcd') }

      context 'longer than stored data' do
        it { expect(buffer.read(2)).to eq('ab') }
      end

      context 'shorter than stored data' do
        it { expect(buffer.read(10)).to eq('abcd') }
      end

      it do
        expect(buffer.read).to eq('abcd')
        expect(buffer.read(10)).to eq(nil)
        buffer.write('abcd')
        expect(buffer.read(2)).to eq('ab')
        expect(buffer.read(2)).to eq('cd')
        expect(buffer.read).to eq(nil)
      end
    end

    context 'when no one wrote data yet' do
      it { expect(buffer.read(10)).to eq(nil) }
    end
  end
end
