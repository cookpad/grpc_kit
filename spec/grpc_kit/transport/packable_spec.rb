# frozen_string_literal: true

require 'grpc_kit/transport/packable'

RSpec.describe GrpcKit::Transport::Packable do
  let(:packable) do
    c = Class.new
    c.include described_class
    c.new
  end

  let(:data) { 'marshaled data' }

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

    context "when the buffer is empty" do
      context 'when feed data is nil' do
        it { expect(packable.unpack(nil)).to be_nil }
      end

      context 'when feed data is a Length-Prefixed-Message' do
        it { expect(packable.unpack(packed_data)).to eq([false, data.bytesize, data]) }
      end
    end

    context "when the buffer is used once" do
      before do
        packable.unpack(packed_data)
      end

      context 'and following data is nil' do
        it { expect(packable.unpack(nil)).to be_nil }
      end

      context 'and following data is a Length-Prefixed-Message' do
        it { expect(packable.unpack(packed_data)).to eq([false, data.bytesize, data]) }
      end
    end

    context 'when the buffer is filled with multiple messages' do
      it 'returns packed_data separately' do
        v = packable.unpack(packed_data + packed_data + packed_data)
        expect(v).to eq([false, data.bytesize, data])
        expect(packable.unpack(nil)).to eq([false, data.bytesize, data])
        expect(packable.unpack(nil)).to eq([false, data.bytesize, data])
        expect(packable.unpack(nil)).to be_nil
      end
    end

    context 'when the buffer contains partial data' do
      it 'returns nil until data completes' do
        expect(packable.unpack(packed_data[0..2])).to eq(nil)
        expect(packable.unpack(packed_data[3..8])).to eq(nil)
        expect(packable.unpack(packed_data[9..11])).to eq(nil)
        expect(packable.unpack(packed_data[12..-1])).to eq([false, data.bytesize, data])
        expect(packable.unpack('')).to be_nil
        expect(packable.unpack(nil)).to be_nil
      end
    end

  end
end
