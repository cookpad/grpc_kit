module GrpcKit
  class RpcDesc
    def initialize(name:, input:, output:, marshal_method:, unmarshal_method:)
      @name = name
      @input = input
      @output = output
      @marshal_method = marshal_method
      @unmarshal_method = unmarshal_method
    end

    def invoke(rpc, val)
      args = @input.send(@unmarshal_method, val)
      ret = rpc.send(to_underscore(@name), args, nil) # nil is GRPC::Call object
      @output.send(@marshal_method, ret)
    end

    def ruby_style_name
      @ruby_style_name ||= to_underscore(@name).to_sym
    end

    def path(service_name)
      "/#{service_name}/#{@name}".to_sym
    end

    private

    def to_underscore(val)
      val
        .to_s
        .gsub(/([A-Z]+)([A-Z][a-z])/, '\1_\2')
        .gsub(/([a-z\d])([A-Z])/, '\1_\2')
        .tr('-', '_')
        .downcase
    end
  end
end
