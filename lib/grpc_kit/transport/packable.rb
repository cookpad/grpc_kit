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
        # Compressed-Flag (1 byte) + Message-Length (4 Bytes)
        PREFIX_SIZE = 5

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
          return nil if @data.bytesize < PREFIX_SIZE

          prefix = @data.byteslice(0, PREFIX_SIZE)
          compressed, length = prefix.unpack('CN')

          return nil if (@data.bytesize-PREFIX_SIZE) < length

          d = @data.freeze
          data = d.byteslice(PREFIX_SIZE, length)
          @data = d.byteslice(PREFIX_SIZE + length, d.bytesize)
          [compressed == 1, length, data]
        end
      end
    end
  end
end
