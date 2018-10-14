# frozen_string_literal: true

module GrpcKit
  module Rpcs
    Context = Struct.new(:metadata, :method, :stream) do
      Name = Struct.new(:name, :receiver)
      Reciver = Struct.new(:class)
      Klass = Struct.new(:service_name)

      def initialize(metadata, method_name, service_name, stream = nil)
        klass = Klass.new(service_name)
        super(metadata, Name.new(method_name, Reciver.new(klass)), stream)
      end

      def recv
        stream.recv
      end

      def send_msg(v)
        stream.send_msg(v)
      end
    end
  end
end
