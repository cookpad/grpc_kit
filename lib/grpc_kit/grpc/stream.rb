# frozen_string_literal: true

require 'grpc_kit/grpc/dsl'
require 'forwardable'

module GrpcKit
  module Grpc
    class Stream
      extend Forwardable
      delegate %i[encode decode] => :@klass

      def initialize(klass)
        @klass = klass
      end

      # FIXME: Do not use method_missing...
      def method_missing(name, *args, &block)
        @klass.send(name, *args, &block)
      end
    end
  end
end
