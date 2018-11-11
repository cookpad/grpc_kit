# frozen_string_literal: true

require 'grpc_kit/session/headers'

RSpec.describe GrpcKit::Session::Headers do
  let(:headers) { described_class.new }
  describe '#add' do
    context 'when :path is given' do
      it { expect { headers.add(':path', '/routeguide.RouteGuide/GetFeature') }.to change { headers.path }.from(nil).to('/routeguide.RouteGuide/GetFeature') }
    end

    context 'when :status is given' do
      it { expect { headers.add(':status', '200') }.to change { headers.http_status }.from(nil).to('200') }
    end

    context 'when grpc-timeout is given' do
      it { expect { headers.add('grpc-timeout', '1S') }.to change { headers.timeout.class }.from(NilClass).to(GrpcKit::GrpcTime) }
    end

    xcontext 'when content-type is given' do
      it { expect { headers.add('content-type', 'application/grpc+proto') }.to change { headers.metadata['content-type'] }.from(nil).to('application/grpc+proto') }
    end

    context 'when grpc-encoding is given' do
      it { expect { headers.add('grpc-encoding', 'identity,gzip') }.to change { headers.grpc_encoding }.from(nil).to('identity,gzip') }
    end

    context 'when grpc-status is given' do
      it { expect { headers.add('grpc-status', '0') }.to change { headers.grpc_status }.from(nil).to('0') }
    end

    context 'when user-agent is given' do
      it { expect { headers.add('user-agent', 'grpc-ruby/1.0 (grpc_kit)') }.to change { headers.metadata['user-agent'] }.from(nil).to('grpc-ruby/1.0 (grpc_kit)') }
    end

    context 'when authority is given' do
      it { expect { headers.add('authority', 'localhost:50051') }.to change { headers.metadata['authority'] }.from(nil).to('localhost:50051') }
    end

    context 'when te is given' do
      it { expect { headers.add('te', 'trailer') }.not_to change { headers.metadata['te'] } }
    end
  end
end
