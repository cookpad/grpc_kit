# frozen_string_literal: true

require 'grpc_kit/session/recv_buffer'

RSpec.describe GrpcKit::Session::RecvBuffer do
  let(:buffer) { described_class.new }

  describe '#end_read' do
    it 'check end_write true' do
      buffer.end_read
      expect(buffer).to be_end_read
    end
  end

  describe '#read' do
    context 'with non-blocking mode' do
      context "with stored data" do
        before do
          buffer.write('abcd')
        end

        it { expect(buffer.read(blocking: false)).to eq('abcd') }

        context 'longer than stored data' do
          it { expect(buffer.read(2, blocking: false)).to eq('ab') }
        end

        context 'shorter than stored data' do
          it { expect(buffer.read(10, blocking: false)).to eq('abcd') }
        end

        it do
          expect(buffer.read(nil, blocking: false)).to eq('abcd')
          expect(buffer.read(10, blocking: false)).to eq(:wait_readable)
          buffer.write('abcd')
          expect(buffer.read(2, blocking: false)).to eq('ab')
          expect(buffer.read(2, blocking: false)).to eq('cd')
          expect(buffer.read(nil, blocking: false)).to eq(:wait_readable)

          buffer.close
          expect(buffer.read(nil, blocking: false)).to eq(nil)
        end
      end

      context 'when no one wrote data yet' do
        it { expect(buffer.read(10, blocking: false)).to eq(:wait_readable) }
      end
    end

    context "with blocking mode" do
      context "with stored data" do
        before do
          buffer.write('abcd')
        end

        it { expect(buffer.read(blocking: true)).to eq('abcd') }

        context 'longer than stored data' do
          it { expect(buffer.read(2, blocking: true)).to eq('ab') }
        end

        context 'shorter than stored data' do
          it { expect(buffer.read(10, blocking: true)).to eq('abcd') }
        end

        it do
          expect(buffer.read(nil, blocking: true)).to eq('abcd')
          buffer.write('abcd')
          expect(buffer.read(2, blocking: true)).to eq('ab')
          expect(buffer.read(2, blocking: true)).to eq('cd')
          buffer.close
          expect(buffer.read(nil, blocking: true)).to eq(nil)
        end
      end

      context "with insufficient data" do
        specify do
          th = Thread.new do
            buffer.read(blocking: true)
          end
          buffer.write('a')
          expect(th.value).to eq('a')
        end
      end
    end
  end
end
