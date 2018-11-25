# frozen_string_literal: true

module GrpcKit
  class ProtoBuffer
    # @param encoder [Class, GrpcKit::GRPC::Stream]
    # @param decoder [Class, GrpcKit::GRPC::Stream]
    # @param encode_method [Symbol]
    # @param decode_method [Symbol]
    def initialize(encoder:, decoder:, encode_method:, decode_method:)
      @encoder = encoder
      @decoder = decoder
      @encode_method = encode_method
      @decode_method = decode_method
    end

    # @param data [String]
    # @return [void]
    def encode(data)
      @encoder.send(@encode_method, data)
    end

    # @param data [String]
    # @return [void]
    def decode(data)
      @decoder.send(@decode_method, data)
    end
  end
end
