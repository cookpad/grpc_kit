# frozen_string_literal: true

require 'grpc_kit/session/control_queue'

RSpec.describe GrpcKit::Session::ControlQueue do
  let(:queue) do
    described_class.new
  end

  describe '#pop' do
    context 'when queue is empty' do
      it { expect(queue.pop).to eq(nil) }
    end

    context 'when queue is not empty' do
      before do
        queue.resume_data('id')
      end

      it { expect(queue.pop).to eq([:resume_data, 'id']) }
    end
  end
end
