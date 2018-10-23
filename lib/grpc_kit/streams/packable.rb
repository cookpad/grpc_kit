# frozen_string_literal: true

module GrpcKit
  module Streams
    module Packable
      # @params data [String]
      # @params compress [Boolean]
      def pack(data, compress = false)
        c = compress ? 1 : 0
        [c, data.bytesize, data].pack('CNa*')
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
        @unpacker ||= GrpcKit::Streams::Packable::Unpacker.new
      end

      class Unpacker
        # Compressed bytes(1 Byte) + length bytes(4 Bytes)
        METADATA_SIZE = 5

        def initialize
          @i = 0
          @data = nil
        end

        def readable?
          @data && !@data.empty?
        end

        def feed(data)
          if @data
            @data << data
          else
            @data = data
          end
        end

        def read
          metadata = @data.slice!(0, METADATA_SIZE)
          c, size = metadata.unpack('CN')
          data = @data.slice!(0, size)
          [c != 0, size, data]
        end
      end
    end
  end
end
