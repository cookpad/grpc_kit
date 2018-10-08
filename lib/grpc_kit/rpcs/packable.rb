# frozen_string_literal: true

require 'forwardable'

module GrpcKit
  module Rpcs
    module Packable
      # @params data [String]
      # @params compress [Boolean]
      def pack(data, compress = false)
        c = compress ? 1 : 0
        [c, data.size, data].pack('CNa*')
      end

      def unpack(data)
        c, size, data = data.unpack('CNa*')
        [c == 1, size, data]
      end
    end
  end
end
