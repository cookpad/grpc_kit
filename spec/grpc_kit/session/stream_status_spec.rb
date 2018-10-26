# frozen_string_literal: true

require 'grpc_kit/session/stream_status'

RSpec.describe GrpcKit::Session::StreamStatus do
  let(:status) { described_class.new }

  describe '#close_local' do
    it { expect { status.close_local }.to change { status.close_local? }.from(false).to(true) }
    it { expect { status.close_local }.not_to change { status.close_remote? } }
    it { expect { status.close_local }.not_to change { status.close? } }

    context 'when status is HALF_CLOSE_REMOTE' do
      before { status.close_remote }

      it { expect { status.close_local }.to change { status.close_local? }.from(false).to(true) }
      it { expect { status.close_local }.not_to change { status.close_remote? } }
      it { expect { status.close_local }.to change { status.close? }.from(false).to(true) }
    end

    context 'when status is HALF_CLOSE_LOCAL' do
      before { status.close_local }

      it { expect { status.close_local }.not_to change { status.close_local? } }
      it { expect { status.close_local }.not_to change { status.close_remote? } }
      it { expect { status.close_local }.not_to change { status.close? } }
    end

    context 'when status is CLOSE' do
      before { status.close }
      it { expect { status.close_local }.to raise_error(RuntimeError) }
    end
  end

  describe '#close_remote' do
    it { expect { status.close_remote }.not_to change { status.close_local? } }
    it { expect { status.close_remote }.to change { status.close_remote? }.from(false).to(true) }
    it { expect { status.close_remote }.not_to change { status.close? } }

    context 'when status is HALF_CLOSE_REMOTE' do
      before { status.close_remote }

      it { expect { status.close_remote }.not_to change { status.close_local? } }
      it { expect { status.close_remote }.not_to change { status.close_remote? } }
      it { expect { status.close_remote }.not_to change { status.close_remote? } }
    end

    context 'when status is HALF_CLOSE_LOCAL' do
      before { status.close_local }

      it { expect { status.close_remote }.not_to change { status.close_local? } }
      it { expect { status.close_remote }.to change { status.close_remote? }.from(false).to(true) }
      it { expect { status.close_remote }.to change { status.close? }.from(false).to(true) }
    end

    context 'when status is CLOSE' do
      before { status.close }
      it { expect { status.close_remote }.to raise_error(RuntimeError) }
    end
  end

  describe '#close' do
    it { expect { status.close }.to change { status.close_local? }.from(false).to(true) }
    it { expect { status.close }.to change { status.close_remote? }.from(false).to(true) }
    it { expect { status.close }.to change { status.close? }.from(false).to(true) }

    context 'when status is HALF_CLOSE_REMOTE' do
      before { status.close_remote }

      it { expect { status.close }.to change { status.close_local? }.from(false).to(true) }
      it { expect { status.close }.not_to change { status.close_remote? } }
      it { expect { status.close }.to change { status.close? }.from(false).to(true) }
    end

    context 'when status is HALF_CLOSE_LOCAL' do
      before { status.close_local }

      it { expect { status.close }.not_to change { status.close_local? } }
      it { expect { status.close }.to change { status.close_remote? }.from(false).to(true) }
      it { expect { status.close }.to change { status.close? }.from(false).to(true) }
    end

    context 'when status is CLOSE' do
      before { status.close }

      it { expect { status.close }.not_to change { status.close? } }
    end
  end

  describe '#close_local?' do
    context 'when status is OPEN' do
      it { expect(status.close_local?).to eq(false) }
    end

    context 'when status is HALF_CLOSE_REMOTE' do
      before do
        status.instance_variable_set(:@status, GrpcKit::Session::StreamStatus::HALF_CLOSE_REMOTE)
      end

      it { expect(status.close_local?).to eq(false) }
    end

    context 'when status is HALF_CLOSE_LOCAL' do
      before do
        status.instance_variable_set(:@status, GrpcKit::Session::StreamStatus::HALF_CLOSE_LOCAL)
      end

      it { expect(status.close_local?).to eq(true) }
    end

    context 'when status is CLOSE' do
      before do
        status.instance_variable_set(:@status, GrpcKit::Session::StreamStatus::CLOSE)
      end

      it { expect(status.close_local?).to eq(true) }
    end
  end

  describe '#close_remote?' do
    context 'when status is OPEN' do
      it { expect(status.close_remote?).to eq(false) }
    end

    context 'when status is HALF_CLOSE_REMOTE' do
      before do
        status.instance_variable_set(:@status, GrpcKit::Session::StreamStatus::HALF_CLOSE_REMOTE)
      end

      it { expect(status.close_remote?).to eq(true) }
    end

    context 'when status is HALF_CLOSE_LOCAL' do
      before do
        status.instance_variable_set(:@status, GrpcKit::Session::StreamStatus::HALF_CLOSE_LOCAL)
      end

      it { expect(status.close_remote?).to eq(false) }
    end

    context 'when status is CLOSE' do
      before do
        status.instance_variable_set(:@status, GrpcKit::Session::StreamStatus::CLOSE)
      end

      it { expect(status.close_remote?).to eq(true) }
    end
  end

  describe '#close?' do
    context 'when status is OPEN' do
      it { expect(status.close?).to eq(false) }
    end

    context 'when status is HALF_CLOSE_REMOTE' do
      before do
        status.instance_variable_set(:@status, GrpcKit::Session::StreamStatus::HALF_CLOSE_REMOTE)
      end

      it { expect(status.close?).to eq(false) }
    end

    context 'when status is HALF_CLOSE_LOCAL' do
      before do
        status.instance_variable_set(:@status, GrpcKit::Session::StreamStatus::HALF_CLOSE_LOCAL)
      end

      it { expect(status.close?).to eq(false) }
    end

    context 'when status is CLOSE' do
      before do
        status.instance_variable_set(:@status, GrpcKit::Session::StreamStatus::CLOSE)
      end

      it { expect(status.close?).to eq(true) }
    end
  end
end
