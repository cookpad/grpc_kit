# frozen_string_literal: true

require 'grpc_kit/session/server_session'
require 'grpc_kit/session/io'

RSpec.describe GrpcKit::Session::ServerSession do
  let(:session) do
    so = GrpcKit::Session::IO.new(io)
    described_class.new(so, double(:dispatcher))
  end

  let(:io) do
    StringIO.new
  end

  before do
    allow(IO).to receive(:select).and_return([[io], []])
  end

  describe '#run_once' do
    before do
      io.write(<<~HTTP_REQUEST)
        GET / HTTP/1.1
        Host: 127.0.0.1:8080

      HTTP_REQUEST
      io.seek(0)
    end

    it 'calls shutdown with log' do
      expect(session).to receive(:shutdown).once
      expect(GrpcKit.logger).to receive(:error).with('Invalid client magic was received').once
      expect(session.run_once).to eq(true)
    end
  end
end
