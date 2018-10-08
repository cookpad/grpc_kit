# frozen_string_literal: true

module GrpcKit
  class ProtoBuffer
    def initialize(encoder:, decoder:, encode_method:, decode_method:)
      @encoder = encoder
      @decoder = decoder
      @encode_method = encode_method
      @decode_method = decode_method
    end

    def encode(data)
      @encoder.send(@encode_method, data)
    end

    def decode(data)
      @decoder.send(@decode_method, data)
    end
  end
end
