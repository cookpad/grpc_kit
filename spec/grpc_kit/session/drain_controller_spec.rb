# frozen_string_literal: true

require 'grpc_kit/session/drain_controller'

RSpec.describe GrpcKit::Session::DrainController do
  let(:drain) { described_class.new }

  it 'calls some methods in order' do
    session = double(:session)
    expect(session).to receive(:submit_shutdown)
    expect(session).to receive(:submit_ping)
    expect(session).not_to receive(:submit_goaway)
    expect(session).not_to receive(:shutdown)
    drain.call(session)

    session = double(:session)
    expect(session).not_to receive(:submit_shutdown)
    expect(session).not_to receive(:submit_ping)
    expect(session).not_to receive(:submit_goaway)
    expect(session).not_to receive(:shutdown)
    drain.call(session)

    drain.recv_ping_ack

    session = double(:session)
    expect(session).not_to receive(:submit_shutdown)
    expect(session).not_to receive(:submit_ping)
    expect(session).to receive(:submit_goaway)
    expect(session).to receive(:last_proc_stream_id)
    # expect(session).not_to receive(:shutdown)
    drain.call(session)

    session = double(:session)
    expect(session).not_to receive(:submit_shutdown)
    expect(session).not_to receive(:submit_ping)
    expect(session).not_to receive(:submit_goaway)
    # expect(session).to receive(:shutdown)
    drain.call(session)
  end
end
