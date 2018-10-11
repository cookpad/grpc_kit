# frozen_string_literal: true

require 'grpc_kit/rpcs'
require 'grpc_kit/protobuffer'

module GrpcKit
  class RpcDesc
    def initialize(name:, marshal:, unmarshal:, marshal_method:, unmarshal_method:, service_name:)
      @name = name
      @marshal = marshal
      @unmarshal = unmarshal
      @marshal_method = marshal_method
      @unmarshal_method = unmarshal_method
      @service_name = service_name
    end

    def build_server(handler)
      server.new(
        handler: handler,
        method_name: ruby_style_name,
        protobuf: server_protobuf,
      )
    end

    def build_client(opts = {})
      @build_client ||= client.new(
        path: path.to_s,
        protobuf: client_protobuf,
        opts: opts,
      )
    end

    def ruby_style_name
      @ruby_style_name ||= to_underscore(@name).to_sym
    end

    def path
      @path ||= "/#{@service_name}/#{@name}".to_sym
    end

    def request_response?
      !@marshal.is_a?(GrpcKit::GRPC::Stream) && !@unmarshal.is_a?(GrpcKit::GRPC::Stream)
    end

    def client_streamer?
      @marshal.is_a?(GrpcKit::GRPC::Stream) && !@unmarshal.is_a?(GrpcKit::GRPC::Stream)
    end

    def server_streamer?
      !@marshal.is_a?(GrpcKit::GRPC::Stream) && @unmarshal.is_a?(GrpcKit::GRPC::Stream)
    end

    def bidi_streamer?
      @marshal.is_a?(GrpcKit::GRPC::Stream) && @unmarshal.is_a?(GrpcKit::GRPC::Stream)
    end

    private

    def server
      @server ||=
        if request_response?
          GrpcKit::Rpcs::Server::RequestResponse
        elsif client_streamer?
          GrpcKit::Rpcs::Server::ClientStreamer
        elsif server_streamer?
          GrpcKit::Rpcs::Server::ServerStreamer
        elsif bidi_streamer?
          GrpcKit::Rpcs::Server::BidiStreamer
        end
    end

    def client
      @client ||=
        if request_response?
          GrpcKit::Rpcs::Client::RequestResponse
        elsif client_streamer?
          GrpcKit::Rpcs::Client::ClientStreamer
        elsif server_streamer?
          GrpcKit::Rpcs::Client::ServerStreamer
        elsif bidi_streamer?
          GrpcKit::Rpcs::Client::BidiStreamer
        end
    end

    def server_protobuf
      @server_protobuf ||= ProtoBuffer.new(
        encoder: @unmarshal,
        decoder: @marshal,
        encode_method: @marshal_method,
        decode_method: @unmarshal_method,
      )
    end

    def client_protobuf
      @client_protobuf ||= ProtoBuffer.new(
        encoder: @marshal,
        decoder: @unmarshal,
        encode_method: @marshal_method,
        decode_method: @unmarshal_method,
      )
    end

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
