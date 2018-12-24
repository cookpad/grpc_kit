# frozen_string_literal: true

require 'grpc_kit/interceptor_registory'

RSpec.describe GrpcKit::InterceptorRegistry do
  let(:interceptor1) do
    Class.new(GrpcKit::Grpc::ClientInterceptor).new
  end

  let(:interceptor2) do
    Class.new(GrpcKit::Grpc::ServerInterceptor).new
  end

  let(:interceptors) do
    [interceptor1, interceptor2]
  end

  let(:registry) do
    described_class.new(interceptors)
  end

  describe 'initialize' do
    context 'when interceptors is nil' do
      let(:interceptors) { nil }

      it 'raises an ArgumentError' do
        expect { registry }.to raise_error(ArgumentError, /nil/)
      end
    end

    context 'when interceptors is empty' do
      let(:interceptors) { [] }

      it 'raises an ArgumentError' do
        expect { registry }.to raise_error(ArgumentError, /empty/)
      end
    end

    context 'when interceptors include not interceptor class' do
      let(:interceptors) { [double(:not_inter), 'test'] }

      it 'raises an ArgumentError' do
        expect { registry }.to raise_error(ArgumentError, /test/)
      end
    end  end

  describe '#build' do
    it 'build interceptors whose contains is same and object id of array is different' do
      inters = registry.build
      expect(inters).to eq(interceptors)
      expect(inters.object_id).not_to eq(interceptors.object_id)

      inters.pop
      expect(inters.size).not_to eq(interceptors.size)
    end
  end
end
