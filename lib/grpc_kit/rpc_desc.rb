# frozen_string_literal: true

require 'grpc_kit/method_config'
require 'grpc_kit/codec'

require 'grpc_kit/interceptors/client_request_response'
require 'grpc_kit/interceptors/client_client_streamer'
require 'grpc_kit/interceptors/client_server_streamer'
require 'grpc_kit/interceptors/client_bidi_streamer'
require 'grpc_kit/rpcs/client_request_response'
require 'grpc_kit/rpcs/client_client_streamer'
require 'grpc_kit/rpcs/client_server_streamer'
require 'grpc_kit/rpcs/client_bidi_streamer'

require 'grpc_kit/interceptors/server_request_response'
require 'grpc_kit/interceptors/server_client_streamer'
require 'grpc_kit/interceptors/server_server_streamer'
require 'grpc_kit/interceptors/server_bidi_streamer'
require 'grpc_kit/rpcs/server_request_response'
require 'grpc_kit/rpcs/server_client_streamer'
require 'grpc_kit/rpcs/server_server_streamer'
require 'grpc_kit/rpcs/server_bidi_streamer'

module GrpcKit
  class RpcDesc
    # @param name [Symbol] path name
    # @param marshal [Class, GrpcKit::Grpc::Stream] marshaling object
    # @param unmarshal [Class, GrpcKit::Grpc::Stream] unmarshaling object
    # @param marshal_method [Symbol] method name of marshaling which marshal is called this method
    # @param unmarshal_method [Symbol] method name of unmarshaling which unmarshal is called this method
    # @param service_name [String]
    def initialize(name:, marshal:, unmarshal:, marshal_method:, unmarshal_method:, service_name:)
      @name = name
      @marshal = marshal
      @unmarshal = unmarshal
      @marshal_method = marshal_method
      @unmarshal_method = unmarshal_method
      @service_name = service_name
    end

    # @param handler [GrpcKit::Grpc::GenericService]
    # @param interceptors [Array<GrpcKit::Grpc::ServerInterceptor>]
    # @return [#invoke] Server version of rpc class
    def build_server(handler, interceptors: [])
      inter = interceptors.empty? ? nil : server_interceptor.new(interceptors)

      config = GrpcKit::MethodConfig.build_for_server(
        path: path,
        ruby_style_method_name: ruby_style_name,
        codec: server_codec,
        service_name: @service_name,
        method_name: @name,
        interceptor: inter,
      )
      server.new(handler, config)
    end

    # @param interceptors [Array<GrpcKit::Grpc::ClientInterceptor>]
    # @return [#invoke] Client version of rpc class
    def build_client(interceptors: [])
      inter = interceptors.empty? ? nil : client_interceptor.new(interceptors)

      config = GrpcKit::MethodConfig.build_for_client(
        path: path,
        ruby_style_method_name: ruby_style_name,
        codec: client_codec,
        service_name: @service_name,
        method_name: @name,
        interceptor: inter,
      )
      client.new(config)
    end

    # @return [Symbol] Snake case name
    def ruby_style_name
      @ruby_style_name ||= to_underscore(@name).to_sym
    end

    # @return [String] Full name of path name
    def path
      @path ||= "/#{@service_name}/#{@name}"
    end

    # @return [Boolean]
    def request_response?
      !@marshal.is_a?(GrpcKit::Grpc::Stream) && !@unmarshal.is_a?(GrpcKit::Grpc::Stream)
    end

    # @return [Boolean]
    def client_streamer?
      @marshal.is_a?(GrpcKit::Grpc::Stream) && !@unmarshal.is_a?(GrpcKit::Grpc::Stream)
    end

    # @return [Boolean]
    def server_streamer?
      !@marshal.is_a?(GrpcKit::Grpc::Stream) && @unmarshal.is_a?(GrpcKit::Grpc::Stream)
    end

    # @return [Boolean]
    def bidi_streamer?
      @marshal.is_a?(GrpcKit::Grpc::Stream) && @unmarshal.is_a?(GrpcKit::Grpc::Stream)
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

    def server_codec
      @server_codec ||= Codec.new(
        marshal: @unmarshal,
        unmarshal: @marshal,
        marshal_method: @marshal_method,
        unmarshal_method: @unmarshal_method,
      )
    end

    def client_codec
      @client_codec ||= Codec.new(
        marshal: @marshal,
        unmarshal: @unmarshal,
        marshal_method: @marshal_method,
        unmarshal_method: @unmarshal_method,
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
        GrpcKit::Interceptors::Server::BidiStreamer
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
        GrpcKit::Interceptors::Client::BidiStreamer
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
