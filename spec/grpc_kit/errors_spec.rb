# frozen_string_literal: true

require 'grpc_kit/errors'
require 'grpc_kit/status_codes'

RSpec.describe GrpcKit::Errors do
  describe '.from_status_code' do
    subject(:error) do
      described_class.from_status_code(code, message)
    end

    let(:message) do
      'test message'
    end

    context 'code is OK' do
      let(:code) do
        GrpcKit::StatusCodes::OK
      end

      it 'raises an ArgumentError' do
        expect { error }.to raise_error(ArgumentError, /OK/)
      end
    end

    context 'code is gRPC error status' do
      let(:code) do
        GrpcKit::StatusCodes::NOT_FOUND
      end

      it 'returns an corresponding error' do
        expect(error).to be_a(GrpcKit::Errors::NotFound)
      end
    end

    context 'code is unknown' do
      let(:code) do
        '1000'
      end

      it 'returns an Unknown errro' do
        expect(error).to be_a(GrpcKit::Errors::Unknown)
        expect(error.message).to match(/code=#{code}/)
      end
    end
  end
end
