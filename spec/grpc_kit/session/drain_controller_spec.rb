# frozen_string_literal: true

require 'grpc_kit/session/drain_controller'

RSpec.describe GrpcKit::Session::DrainController do
  let(:draining_time) { 0 }
  let(:drain) { described_class.new(draining_time) }

  describe '#next' do
    it 'always performs nothing' do
      session = double(:session)
      expect(session).not_to receive(:submit_shutdown)
      expect(session).not_to receive(:submit_ping)
      expect(session).not_to receive(:submit_goaway)
      expect(session).not_to receive(:shutdown)
      drain.next(session)
    end

    context 'after called #start_draining' do
      before { drain.start_draining }

      it 'calls some methods in order' do
        session = double(:session)
        expect(session).to receive(:submit_shutdown)
        expect(session).not_to receive(:submit_ping)
        expect(session).not_to receive(:submit_goaway)
        expect(session).not_to receive(:shutdown)
        drain.next(session)

        session = double(:session)
        expect(session).not_to receive(:submit_shutdown)
        expect(session).to receive(:submit_ping)
        expect(session).not_to receive(:submit_goaway)
        expect(session).not_to receive(:shutdown)
        drain.next(session)

        session = double(:session)
        expect(session).not_to receive(:submit_shutdown)
        expect(session).not_to receive(:submit_ping)
        expect(session).not_to receive(:submit_goaway)
        expect(session).not_to receive(:shutdown)
        drain.next(session)

        drain.recv_ping_ack

        session = double(:session)
        expect(session).not_to receive(:submit_shutdown)
        expect(session).not_to receive(:submit_ping)
        expect(session).to receive(:submit_goaway)
        expect(session).to receive(:last_proc_stream_id)
        expect(session).not_to receive(:shutdown)
        drain.next(session)

        session = double(:session)
        expect(session).not_to receive(:submit_shutdown)
        expect(session).not_to receive(:submit_ping)
        expect(session).not_to receive(:submit_goaway)
        # expect(session).to receive(:shutdown)
        drain.next(session)
      end

      context 'but recv_ping_ack is not called' do
        it 'does not change itself status' do
          session = double(:session, submit_shutdown: nil, submit_ping: nil)
          drain.next(session)
          drain.next(session)

          session = double(:session)
          expect(session).not_to receive(:submit_shutdown)
          expect(session).not_to receive(:submit_ping)
          expect(session).not_to receive(:submit_goaway)
          expect(session).not_to receive(:last_proc_stream_id)
          expect(session).not_to receive(:shutdown)
          drain.next(session)
        end
      end
    end
  end
end
