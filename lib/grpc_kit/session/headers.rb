# frozen_string_literal: true

require 'grpc_kit/grpc_time'

module GrpcKit
  module Session
    class Headers
      RESERVED_HEADERS = [
        ':path', ':status', ':scheme',
        'content-type', 'grpc-message-type', 'grpc-timeout',
        'grpc-encoding', 'grpc-message', 'grpc-status',
        'grpc-status-details-bin', 'grpc-accept-encoding', 'te',
        ':method'
      ].freeze

      METADATA_ACCEPTABLE_HEADER = %w[:authority user-agent].freeze

      def initialize
        @opts = {}
        @metadata = {}
      end

      def metadata
        @metadata =
          if @metadata.empty?
            @opts.select do |key|
              !key.start_with?(':', 'grpc-') && !RESERVED_HEADERS.include?(key)
            end
          else
            @metadata
          end
      end

      def path
        @opts[':path']
      end

      def grpc_status
        @opts['grpc-status']
      end

      def grpc_encoding
        @opts['grpc-encoding']
      end

      def content_type
        @opts['content-type']
      end

      def status_message
        @opts['grpc-message']
      end

      def timeout
        @timeout ||= @opts['grpc-timeout'] && GrpcTime.new(@opts['grpc-timeout'])
      end

      def http_status
        @opts[':status']
      end

      def add(key, val)
        @opts[key] = val
      end
    end
  end
end
