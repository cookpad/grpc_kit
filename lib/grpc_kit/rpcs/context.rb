# frozen_string_literal: true

module GrpcKit
  module Rpcs
    Context = Struct.new(:metadata, :method) do
      Name = Struct.new(:name, :receiver)
      Reciver = Struct.new(:class)
      Klass = Struct.new(:service_name)

      def initialize(metadata, method_name, service_name)
        klass = Klass.new(service_name)
        super(metadata, Name.new(method_name, Reciver.new(klass)))
      end
    end
  end
end
