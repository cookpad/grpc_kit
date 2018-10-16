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

      # @params data [String]
      def unpack(data)
        if data
          unpacker.feed(data)
        end

        if unpacker.readable?
          return unpacker.read
        end

        nil
      end

      def unpacker
        @unpacker ||= GrpcKit::Rpcs::Packable::Unpacker.new
      end

      class Unpacker
        # Compressed bit(1Byte) + length bits(4Bytes)
        METADATA_SIZE = 5

        def initialize
          @i = 0
          @data = nil
        end

        def readable?
          @data.size > @i
        end

        def feed(data)
          if @data
            @data << data
          else
            @data = data
          end
        end

        def read
          c, size = @data.unpack('CN')
          @i += METADATA_SIZE
          data = @data.byteslice(@i, size)
          @i += size
          [c != 0, size, data]
        end
      end
    end
  end
end
