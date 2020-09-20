require 'grpc_kit/transport/server_transport'

RSpec.describe GrpcKit::Transport::ServerTransport do
  let(:control_queue) { double(:control_queue) }
  let(:stream) { double(:stream) }

  let(:transport) { described_class.new(control_queue, stream) }

  describe "#read_data" do
    context "when complete data always received" do
      before do
        allow(stream).to receive(:read_recv_data).with(last: false, blocking: true).and_return(
          [0, 5, 'abcde'].pack('CNa*'),
          [0, 5, '12345'].pack('CNa*'),
          nil
        )
      end

      specify do
        expect(transport.read_data).to eq([false, 5, 'abcde'])
        expect(transport.read_data).to eq([false, 5, '12345'])
        expect(transport.read_data).to eq(nil)
        expect(transport.read_data).to eq(nil)
      end
    end

    context "when incomplete data always received" do
      before do
        allow(stream).to receive(:read_recv_data).with(last: false, blocking: true).and_return(
          [0, 5, 'abcde'].pack('CNa*')[0..4],
          [0, 5, 'abcde'].pack('CNa*')[5..-1],
          [0, 5, '12345'].pack('CNa*')[0..6],
          [0, 5, '12345'].pack('CNa*')[7..-1],
          nil
        )
      end

      specify do
        expect(transport.read_data).to eq([false, 5, 'abcde'])
        expect(transport.read_data).to eq([false, 5, '12345'])
        expect(transport.read_data).to eq(nil)
        expect(transport.read_data).to eq(nil)
      end
    end

    context "when incomplete data or empty received" do
      before do
        allow(stream).to receive(:read_recv_data).with(last: false, blocking: true).and_return(
          [0, 5, 'abcde'].pack('CNa*')[0..4],
          '',
          [0, 5, 'abcde'].pack('CNa*')[5..-1],
          '',
          '',
          '',
          [0, 5, '12345'].pack('CNa*')[0..3],
          '',
          '',
          '',
          '',
          [0, 5, '12345'].pack('CNa*')[4..6],
          [0, 5, '12345'].pack('CNa*')[7..-1],
          nil
        )
      end

      specify do
        expect(transport.read_data).to eq([false, 5, 'abcde'])
        expect(transport.read_data).to eq([false, 5, '12345'])
        expect(transport.read_data).to eq(nil)
        expect(transport.read_data).to eq(nil)
      end
    end

    context "when multiple complete data received at once" do
      before do
        allow(stream).to receive(:read_recv_data).with(last: false, blocking: true).and_return(
          [0, 5, 'abcde'].pack('CNa*') + [0, 5, '12345'].pack('CNa*'),
          nil
        )
      end

      specify do
        expect(transport.read_data).to eq([false, 5, 'abcde'])
        expect(transport.read_data).to eq([false, 5, '12345'])
        expect(transport.read_data).to eq(nil)
      end
    end

    context "mixed situation 1" do
      before do
        allow(stream).to receive(:read_recv_data).with(last: false, blocking: true).and_return(
          [0, 5, '12345'].pack('CNa*') + [0, 5, 'xxxxx'].pack('CNa*')[0..4],
          [0, 5, 'xxxxx'].pack('CNa*')[5..-1],
          nil
        )
      end

      specify do
        expect(transport.read_data).to eq([false, 5, '12345'])
        expect(transport.read_data).to eq([false, 5, 'xxxxx'])
        expect(transport.read_data).to eq(nil)
      end
    end

    context "mixed situation 2" do
      before do
        allow(stream).to receive(:read_recv_data).with(last: false, blocking: true).and_return(
          [0, 5, 'abcde'].pack('CNa*')[0..4],
          '',
          [0, 5, 'abcde'].pack('CNa*')[5..-1],
          '',
          '',
          [0, 5, '12345'].pack('CNa*')[0..4],
          '',
          [0, 5, '12345'].pack('CNa*')[5..-1] + [0, 5, 'xxxxx'].pack('CNa*'),
          nil
        )
      end

      specify do
        expect(transport.read_data).to eq([false, 5, 'abcde'])
        expect(transport.read_data).to eq([false, 5, '12345'])
        expect(transport.read_data).to eq([false, 5, 'xxxxx'])
        expect(transport.read_data).to eq(nil)
      end
    end
  end
end

