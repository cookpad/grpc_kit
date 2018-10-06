# frozen_string_literal: true

require 'grpc_kit/errors'
require 'grpc_kit/rpc_desc'
require 'grpc_kit/grpc/stream'

module GrpcKit
  module GRPC
    module Dsl
      attr_accessor :service_name

      attr_writer :marshal_class_method, :unmarshal_class_method

      def inherited(subclass)
        subclass.rpc_descs.merge!(rpc_descs)
        subclass.service_name = service_name
      end

      def rpc(name, input, output)
        if rpc_descs.key?(name)
          raise "rpc (#{name}) is already defined"
        end

        unless input.respond_to?(@marshal_class_method)
          raise "#{marshal} must implement #{marshal}.#{@marshal_class_method}"
        end

        unless output.respond_to?(@unmarshal_class_method)
          raise "#{unmarshal} must implement #{unmarshal}.#{@unmarshal_class_method}"
        end

        # create StreamDesc?
        rpc_descs[name] = GrpcKit::RpcDesc.new(
          name: name,
          input: input,
          output: output,
          marshal_method: @marshal_class_method,
          unmarshal_method: @unmarshal_class_method,
        )

        define_method(rpc_descs[name].ruby_style_name) do |_, _|
          raise GrpcKit::Errors::Unimplemented, name.to_s
        end
      end

      def stream(cls)
        GrpcKit::GRPC::Stream.new(cls)
      end

      def rpc_stub_class
        # TODO
      end

      def rpc_descs
        @rpc_descs ||= {}
      end
    end
  end
end
