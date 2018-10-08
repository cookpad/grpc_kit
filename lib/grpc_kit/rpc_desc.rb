# frozen_string_literal: true

require 'grpc_kit/grpc/stream'

module GrpcKit
  class RpcDesc
    def initialize(name:, input:, output:, marshal_method:, unmarshal_method:)
      @name = name
      @input = input
      @output = output
      @marshal_method = marshal_method
      @unmarshal_method = unmarshal_method
    end

    def encode(val)
      @output.send(@marshal_method, val)
    end

    def decode(val)
      @input.send(@unmarshal_method, val)
    end

    def encode2(val)
      @input.send(@marshal_method, val)
    end

    def decode2(val)
      @output.send(@unmarshal_method, val)
    end

    def invoke(rpc, val)
      args = decode(val)
      ret = rpc.send(to_underscore(@name), args, nil) # nil is GRPC::Call object
      encode(ret)
    end

    def ruby_style_name
      @ruby_style_name ||= to_underscore(@name).to_sym
    end

    def path(service_name)
      "/#{service_name}/#{@name}".to_sym
    end

    def request_response?
      !@input.is_a?(GrpcKit::GRPC::Stream) && !@output.is_a?(GrpcKit::GRPC::Stream)
    end

    def client_streamer?
      @input.is_a?(GrpcKit::GRPC::Stream) && !@output.is_a?(GrpcKit::GRPC::Stream)
    end

    def server_streamer?
      !@input.is_a?(GrpcKit::GRPC::Stream) && @output.is_a?(GrpcKit::GRPC::Stream)
    end

    def bidi_streamer?
      @input.is_a?(GrpcKit::GRPC::Stream) && @output.is_a?(GrpcKit::GRPC::Stream)
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
