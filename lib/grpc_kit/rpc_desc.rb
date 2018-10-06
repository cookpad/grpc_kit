module GrpcKit
  class RpcDesc
    def initialize(name:, marshal:, unmarshal:, marshal_method:, unmarshal_method:)
      @name = name
      @marshal = marshal
      @unmarshal = unmarshal
      @marshal_method = marshal_method
      @unmarshal_method = unmarshal_method
    end
  end
end
