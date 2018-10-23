# frozen_string_literal: true

require 'grpc_kit/interceptors'
require 'grpc_kit/grpc/interceptor'

RSpec.describe GrpcKit::Rpcs::Call do
  let(:call) { described_class.new(method, method_name, service_name, stream) }
  let(:method) { double(:metadata) }
  let(:method_name) { 'method_name' }
  let(:service_name) { 'routeguide.RouteGuide' }
  let(:stream) { double(:stream) }

  describe '#method' do
    it do
      expect(call.method.name).to eq(method_name)
      expect(call.method.receiver.class.service_name).to eq(service_name)
    end
  end
end
