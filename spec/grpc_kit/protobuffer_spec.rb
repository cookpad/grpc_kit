# frozen_string_literal: true

require 'grpc_kit/protobuffer'

RSpec.describe GrpcKit::ProtoBuffer do
  subject(:proto_buffer) do
    described_class.new(
      encoder: encoder,
      decoder: decoder,
      encode_method: encode_method,
      decode_method: decode_method,
    )
  end

  let(:encoder) do
    Class.new do
      def encode(data); end
    end
  end

  let(:decoder) do
    Class.new do
      def decode(data); end
    end
  end

  let(:encode_method) { :encode }
  let(:decode_method) { :decode }
  let(:data) { 'data' }

  describe '#encode' do
    it 'call encode_method' do
      expect(encoder).to receive(encode_method).with(data)

      proto_buffer.encode(data)
    end
  end

  describe '#decode' do
    it 'call decode_method' do
      expect(decoder).to receive(decode_method).with(data)

      proto_buffer.decode(data)
    end
  end
end
