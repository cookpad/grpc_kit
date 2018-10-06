# frozen_string_literal: true

require 'grpc_kit/errors'
require 'grpc_kit/rpc_desc'
require 'grpc_kit/grpc/stream'

module GrpcKit
  module GRPC
    module Dsl
      attr_accessor :service_name

      attr_writer :marshal_class_method, :unmarshal_class_method

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

        # create StreamDesc?
        rpc_descs[name] = GrpcKit::RpcDesc.new(
          name: name,
          marshal: marshal,
          unmarshal: unmarshal,
          marshal_method: @marshal_class_method,
          unmarshal_method: @unmarshal_class_method,
        )

        define_method(to_underscore(name).to_sym) do |_, _|
          raise GrpcKit::Errors::Unimplemented, name.to_s
        end
      end

      def stream(cls)
        GrpcKit::GRPC::Stream.new(cls)
      end

      def rpc_stub_class
        # TODO
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

      def rpc_descs
        @rpc_decs ||= {}
      end
    end
  end
end
