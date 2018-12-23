# frozen_string_literal: true

module GrpcKit
  class Codec
    # @param marshal [Class, GrpcKit::Grpc::Stream]
    # @param unmarshal [Class, GrpcKit::Grpc::Stream]
    # @param marshal_method [Symbol]
    # @param unmarshal_method [Symbol]
    def initialize(marshal:, unmarshal:, marshal_method:, unmarshal_method:)
      @marshal = marshal
      @unmarshal = unmarshal
      @marshal_method = marshal_method
      @unmarshal_method = unmarshal_method
    end

    # @param data [String]
    # @return [String]
    def encode(data)
      @marshal.send(@marshal_method, data)
    end

    # @param data [String]
    # @return [String]
    def decode(data)
      @unmarshal.send(@unmarshal_method, data)
    end
  end
end
