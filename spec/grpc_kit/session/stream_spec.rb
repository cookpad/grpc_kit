# frozen_string_literal: true

require 'grpc_kit/streams/packable'

RSpec.describe GrpcKit::Session::Stream do
  let(:stream) { described_class.new(stream_id: 1, send_data: send_data, recv_data: recv_data) }
  let(:send_data) { double(:send_data, 'end_write?': false) }
  let(:recv_data) { double(:recv_data, 'end_read?': false) }
  let(:data) { 'data' }

  describe '#write_send_data' do
    it 'call wirte method of @pending_send_data' do
      expect(send_data).to receive(:write).with(data, last: false)

      expect(stream.write_send_data(data, last: false))
    end
  end

  describe '#write_recv_data' do
    it 'call read method of @pending_recv_data' do
      expect(recv_data).to receive(:read).with(last: false)

      expect(stream.read_recv_data(last: false))
    end
  end

  describe '#end_write?' do
    it { expect(stream.end_write?).to eq(false) }

    context 'local_end_stream is true' do
      before { stream.local_end_stream = true }
      it { expect(stream.end_write?).to eq(true) }
    end

    context 'pending_send_data ends write' do
      before { allow(send_data).to receive(:'end_write?').and_return(true) }

      it { expect(stream.end_write?).to eq(true) }
    end
  end

  describe '#end_read?' do
    it { expect(stream.end_read?).to eq(false) }

    context 'remote_end_stream is true' do
      before { stream.remote_end_stream = true }
      it { expect(stream.end_read?).to eq(true) }
    end

    context 'pending_recv_data ends write' do
      before { allow(recv_data).to receive(:'end_read?').and_return(true) }

      it { expect(stream.end_read?).to eq(true) }
    end
  end

  describe '#end_stream' do
    it 'call end_read and end_write' do
      expect(stream).to receive(:end_read).once
      expect(stream).to receive(:end_write).once
      stream.end_stream
    end
  end

  describe '#end_stream?' do
    it { expect(stream.end_stream?).to be(false) }

    context 'both end_read? and end_write? return true' do
      before do
        stream.remote_end_stream = true
        stream.local_end_stream = true
      end

      it { expect(stream.end_stream?).to be(true) }
    end
  end

  describe '#end_stream?' do
    let(:headers) { double(:headers) }

    before do
      allow(GrpcKit::Session::Headers).to receive(:new).and_return(headers)
    end

    it 'call add method of headers' do
      name = 'name'
      value = 'value'
      expect(headers).to receive(:add).with(name, value)
      stream.add_header(name, value)
    end
  end
end
