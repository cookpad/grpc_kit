# frozen_string_literal: true

require 'forwardable'

module GrpcKit
  module Rpcs
    # compatible for grpc gem
    class Call
      extend Forwardable

      delegate %i[recv send_msg close_and_recv each].freeze => :@stream

      Name = Struct.new(:name, :receiver)
      Reciver = Struct.new(:class)
      Klass = Struct.new(:service_name)

      attr_reader :metadata, :method

      def initialize(metadata, method_name, service_name, stream)
        @metadata = metadata
        klass = Klass.new(service_name)
        @method = Name.new(method_name, Reciver.new(klass))
        @stream = stream
      end
    end
  end
end
