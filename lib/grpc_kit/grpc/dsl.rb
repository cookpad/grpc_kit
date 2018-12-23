# frozen_string_literal: true

require 'grpc_kit/errors'
require 'grpc_kit/rpc_desc'
require 'grpc_kit/client'
require 'grpc_kit/grpc/stream'

module GrpcKit
  module Grpc
    module Dsl
      # @param value [String]
      attr_accessor :service_name

      # @param value [Symbol]
      attr_writer :marshal_class_method

      # @param value [Symbol]
      attr_writer :unmarshal_class_method

      def inherited(subclass)
        subclass.rpc_descs.merge!(rpc_descs)
        subclass.service_name = @service_name
      end

      # @param name [Symbol] gRPC method name
      # @param marshal [Class, GrpcKit::Grpc::Stream] marshaling object
      # @param unmarshal [Class, GrpcKit::Grpc::Stream] unmarshaling object
      # @return [void]
      def rpc(name, marshal, unmarshal)
        if rpc_descs.key?(name)
          raise "rpc (#{name}) is already defined"
        end

        unless marshal.respond_to?(@marshal_class_method)
          raise "#{marshal} must implement #{marshal}.#{@marshal_class_method}"
        end

        unless unmarshal.respond_to?(@unmarshal_class_method)
          raise "#{unmarshal} must implement #{unmarshal}.#{@unmarshal_class_method}"
        end

        rpc_desc = GrpcKit::RpcDesc.new(
          name: name,
          marshal: marshal,
          unmarshal: unmarshal,
          marshal_method: @marshal_class_method,
          unmarshal_method: @unmarshal_class_method,
          service_name: @service_name,
        )
        rpc_descs[rpc_desc.path] = rpc_desc

        # Should use `*` since each rpc's sigunature is different.
        define_method(rpc_desc.ruby_style_name) do |*|
          raise GrpcKit::Errors::Unimplemented, "Method not found: #{name}"
        end
      end

      # @return [GrpcKit::Grpc::Stream]
      def stream(cls)
        GrpcKit::Grpc::Stream.new(cls)
      end

      # @return [GrpcKit::Client]
      def rpc_stub_class
        rpc_descs_ = {}
        rpc_descs.each_value do |rpc_desc|
          rpc_descs_[rpc_desc.ruby_style_name] = rpc_desc
        end

        Class.new(GrpcKit::Client) do
          def initialize(*)
            @rpcs = {}
            super
          end

          define_method(:build_rpcs) do |interceptors|
            rpc_descs_.each do |method_name, rpc_desc|
              @rpcs[method_name] = rpc_desc.build_client(interceptors: interceptors)
            end
          end
          private :build_rpcs

          rpc_descs_.each do |method_name, rpc_desc|
            if rpc_desc.request_response?
              define_method(method_name) do |request, opts = {}|
                request_response(@rpcs.fetch(method_name), request, opts)
              end
            elsif rpc_desc.client_streamer?
              define_method(method_name) do |opts = {}|
                client_streamer(@rpcs.fetch(method_name), opts)
              end
            elsif rpc_desc.server_streamer?
              define_method(method_name) do |request, opts = {}|
                server_streamer(@rpcs.fetch(method_name), request, opts)
              end
            elsif rpc_desc.bidi_streamer?
              define_method(method_name) do |requests, opts = {}, &blk|
                bidi_streamer(@rpcs.fetch(method_name), requests, opts, &blk)
              end
            else
              raise "unknown #{rpc_desc}"
            end
          end
        end
      end

      # @return [Hash<String,GrpcKit::RpcDesc>]
      def rpc_descs
        @rpc_descs ||= {}
      end
    end
  end
end
