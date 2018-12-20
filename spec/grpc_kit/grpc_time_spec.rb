# frozen_string_literal: true

require 'grpc_kit/grpc_time'

RSpec.describe GrpcKit::GrpcTime do
  describe '#initialize' do
    it { expect(described_class.new(1)).to be_a(described_class) }

    context 'when string is given' do
      it do
        expect(described_class.new('1H')).to be_a(described_class)
        expect(described_class.new('1M')).to be_a(described_class)
        expect(described_class.new('1S')).to be_a(described_class)
        expect(described_class.new('1m')).to be_a(described_class)
        expect(described_class.new('1u')).to be_a(described_class)
        expect(described_class.new('1n')).to be_a(described_class)
      end

      context 'when invalid format' do
        it { expect { described_class.new('1') }.to raise_error(ArgumentError, /too short/) }
        it { expect { described_class.new('11') }.to raise_error(ArgumentError, /Invalid unit/) }
        it { expect { described_class.new('123456789S') }.to raise_error(ArgumentError, /too long/) }
      end
    end

    context 'when other object is given' do
      it { expect { described_class.new(Object.new) }.to raise_error(ArgumentError) }
    end
  end

  describe 'to_s' do
    it do
      expect(described_class.new(1).to_s).to eq('1S')
      expect(described_class.new(-1).to_s).to eq('999999999S')
      expect(described_class.new('1H').to_s).to eq('1H')
      expect(described_class.new('1M').to_s).to eq('1M')
      expect(described_class.new('1S').to_s).to eq('1S')
      expect(described_class.new('1m').to_s).to eq('1m')
      expect(described_class.new('1u').to_s).to eq('1u')
      expect(described_class.new('1n').to_s).to eq('1n')
    end
  end

  describe 'to_absolute_time' do
    let(:now) { Time.at(0) }
    before { allow(Time).to receive(:now).and_return(now) }

    it do
      expect(described_class.new(1).to_absolute_time.to_i).to eq(now.to_i + 1)
      expect(described_class.new(-1).to_absolute_time.to_i).to eq(10**9 - 1)
      expect(described_class.new('1H').to_absolute_time.to_i).to eq(now.to_i + 60 * 60)
      expect(described_class.new('1M').to_absolute_time.to_i).to eq(now.to_i + 60)
      expect(described_class.new('1S').to_absolute_time.to_i).to eq(now.to_i + 1)
      expect(described_class.new('1m').to_absolute_time.nsec).to eq(10**6)
      expect(described_class.new('1u').to_absolute_time.nsec).to eq(10**3)
      expect(described_class.new('1n').to_absolute_time.nsec).to eq(1)
    end
  end

  describe 'to_f' do
    it do
      expect(described_class.new(-1).to_f).to eq(10**9 - 1 * 1.0)
      expect(described_class.new(1).to_f).to eq(1)
      expect(described_class.new('1H').to_f).to eq(60 * 60)
      expect(described_class.new('1M').to_f).to eq(60)
      expect(described_class.new('1S').to_f).to eq(1)
      expect(described_class.new('1m').to_f).to eq(10**-3)
      expect(described_class.new('1u').to_f).to eq(10**-6)
      expect(described_class.new('1n').to_f).to eq(10**-9)
    end
  end
end
