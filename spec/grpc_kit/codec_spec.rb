# frozen_string_literal: true

require 'grpc_kit/codec'

RSpec.describe GrpcKit::Codec do
  subject(:codec) do
    described_class.new(
      marshal: marshal,
      unmarshal: unmarshal,
      marshal_method: marshal_method,
      unmarshal_method: unmarshal_method,
    )
  end

  let(:marshal) do
    Class.new do
      def encode(data); end
    end
  end

  let(:unmarshal) do
    Class.new do
      def decode(data); end
    end
  end

  let(:marshal_method) { :encode }
  let(:unmarshal_method) { :decode }
  let(:data) { 'data' }

  describe '#encode' do
    it 'call marshal_method' do
      expect(marshal).to receive(marshal_method).with(data)

      codec.encode(data)
    end
  end

  describe '#decode' do
    it 'call unmarshal_method' do
      expect(unmarshal).to receive(unmarshal_method).with(data)

      codec.decode(data)
    end
  end
end
