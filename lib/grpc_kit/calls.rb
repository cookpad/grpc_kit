# frozen_string_literal: true

module GrpcKit
  module Calls
    class Call
      Name = Struct.new(:name, :receiver)
      Reciver = Struct.new(:class)
      Klass = Struct.new(:service_name)
      attr_reader :method

      def initialize(stream:, config:, metadata:, timeout: nil)
        @config = config
        @metadata = metadata
        @method_name = @config.method_name
        @service_name = @config.service_name
        @protobuf = @config.protobuf
        @timeout = timeout
        @stream = stream

        # for compatible
        klass = Klass.new(@service_name)
        @method ||= Name.new(@method_name, Reciver.new(klass))
        @restrict = false
      end

      def restrict_mode
        @restrict = true
      end

      def normal_mode
        @restrict = false
      end

      def deadline
        @deadline ||= @timeout.to_absolute_time
      end
    end
  end
end
