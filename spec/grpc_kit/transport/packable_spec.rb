# frozen_string_literal: true

require 'grpc_kit/transport/packable'

RSpec.describe GrpcKit::Transport::Packable do
  let(:packable) do
    c = Class.new
    c.include described_class
    c.new
  end

  let(:data) { 'protobuff data' }

  describe '#pack' do
    # Length-Prefixed-Message → Compressed-Flag Message-Length Message
    it 'pack Length-Prefixed-Message' do
      d = packable.pack(data)
      expect(d.unpack('CNa*')).to eq([0, data.bytesize, data])
    end

    context 'when compress is true' do
      it 'pack Length-Prefixed-Message' do
        d = packable.pack(data, true)
        expect(d.unpack('CNa*')).to eq([1, data.bytesize, data])
      end
    end
  end

  describe '#unpack' do
    let(:packed_data) do
      [0, data.bytesize, data].pack('CNa*')
    end

    context 'when data is nil' do
      it { expect(packable.unpack(nil)).to be_nil }
    end

    context 'when data is string' do
      it { expect(packable.unpack(packed_data)).to eq([false, data.bytesize, data]) }

      context 'and following data is nil' do
        it { expect(packable.unpack(nil)).to be_nil }
      end

      context 'and following data is string' do
        it { expect(packable.unpack(packed_data)).to eq([false, data.bytesize, data]) }
      end

      context 'and  data has multiple packed_data' do
        it 'return packed_data separately' do
          v = packable.unpack(packed_data + packed_data + packed_data)
          expect(v).to eq([false, data.bytesize, data])
          expect(packable.unpack(nil)).to eq([false, data.bytesize, data])
          expect(packable.unpack(nil)).to eq([false, data.bytesize, data])
          expect(packable.unpack(nil)).to be_nil
        end
      end
    end
  end
end
