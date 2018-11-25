# frozen_string_literal: true

module GrpcKit
  module Transport
    module Packable
      # @param data [String]
      # @param compress [Boolean]
      # @return [String] packed value
      def pack(data, compress = false)
        c = compress ? 1 : 0
        [c, data.bytesize, data].pack('CNa*')
      end

      # @param data [String]
      # @return [String]
      def unpack(data)
        unpacker.feed(data) if data

        unpacker.read
      end

      def unpacker
        @unpacker ||= Unpacker.new
      end

      class Unpacker
        # Compressed bytes(1 Byte) + length bytes(4 Bytes)
        METADATA_SIZE = 5

        def initialize
          @data = +''.b
        end

        # @return [Boolean]
        def data_exist?
          !@data.empty?
        end

        # @param data [String]
        # @return [void]
        def feed(data)
          @data << data
        end

        # @return [nil, Array<Boolean, Integer, String>]
        def read
          return nil if @data.empty?

          d = @data.freeze
          metadata = d.byteslice(0, METADATA_SIZE)
          c, size = metadata.unpack('CN')
          data = @data.byteslice(METADATA_SIZE, size)
          @data = @data.byteslice(METADATA_SIZE + size, @data.bytesize)
          [c != 0, size, data]
        end
      end
    end
  end
end
