# frozen_string_literal: true

require 'grpc_kit/method_config'
require 'grpc_kit/protobuffer'

require 'grpc_kit/interceptors/client_request_response'
require 'grpc_kit/interceptors/client_client_streamer'
require 'grpc_kit/interceptors/client_server_streamer'
# require 'grpc_kit/client_interceptors/bidi_streamer'
require 'grpc_kit/rpcs/client_request_response'
require 'grpc_kit/rpcs/client_client_streamer'
require 'grpc_kit/rpcs/client_server_streamer'
require 'grpc_kit/rpcs/client_bidi_streamer'

require 'grpc_kit/interceptors/server_request_response'
require 'grpc_kit/interceptors/server_client_streamer'
require 'grpc_kit/interceptors/server_server_streamer'
# require 'grpc_kit/server_interceptors/bidi_streamer'
require 'grpc_kit/rpcs/server_request_response'
require 'grpc_kit/rpcs/server_client_streamer'
require 'grpc_kit/rpcs/server_server_streamer'
require 'grpc_kit/rpcs/server_bidi_streamer'

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

    def build_server(handler, interceptors: [])
      inter = interceptors.empty? ? nil : server_interceptor.new(interceptors)

      config = GrpcKit::MethodConfig.build_for_server(
        path: path,
        ruby_style_method_name: ruby_style_name,
        protobuf: server_protobuf,
        service_name: @server_name,
        method_name: @name,
        interceptor: inter,
      )
      server.new(handler, config)
    end

    def build_client
      config = GrpcKit::MethodConfig.build_for_client(
        path: path,
        ruby_style_method_name: ruby_style_name,
        protobuf: client_protobuf,
        service_name: @server_name,
        method_name: @name,
        interceptor: client_interceptor.new,
      )
      client.new(config)
    end

    def ruby_style_name
      @ruby_style_name ||= to_underscore(@name).to_sym
    end

    def path
      @path ||= "/#{@service_name}/#{@name}"
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

    def server_interceptor
      if request_response?
        GrpcKit::Interceptors::Server::RequestResponse
      elsif client_streamer?
        GrpcKit::Interceptors::Server::ClientStreamer
      elsif server_streamer?
        GrpcKit::Interceptors::Server::ServerStreamer
      elsif bidi_streamer?
        GrpcKit::Interceptors::Server::RequestResponse # TODO
      end
    end

    def client_interceptor
      if request_response?
        GrpcKit::Interceptors::Client::RequestResponse
      elsif client_streamer?
        GrpcKit::Interceptors::Client::ClientStreamer
      elsif server_streamer?
        GrpcKit::Interceptors::Client::ServerStreamer
      elsif bidi_streamer?
        GrpcKit::Interceptors::Client::RequestResponse # TODO
      end
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
