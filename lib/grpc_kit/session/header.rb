# frozen_string_literal: true

require 'grpc_kit/session/duration'

module GrpcKit
  module Session
    Header = Struct.new(
      :metadata,
      :path,
      :grpc_encoding,
      :grpc_status,
      :status_message,
      :timeout,
      :method,
      :http_status,
    )

    RESERVED_HEADERS = [
      'content-type',
      'user-agent',
      'grpc-message-type',
      'grpc-encoding',
      'grpc-message',
      'grpc-status',
      'grpc-status-details-bin',
      'te'
    ].freeze

    METADATA_ACCEPTABLE_HEADER = %w[authority user-agent].freeze

    class HeaderProcessor
      def self.call(key, val, headers)
        case key
        when ':path'
          headers.path = val.to_sym
        when ':status'
          headers.http_status = val.to_i
        when 'content-type'
          # TODO
          headers.metadata[key] = val
        when 'grpc-encoding'
          headers.grpc_encoding = val
        when 'grpc-status'
          headers.grpc_status = val.to_i
        when 'grpc-timeout'
          headers.timeout = Duration.decod(v)
        when 'grpc-message'
          # TODO
          GrpcKit.logger.warn('grpc-message is unsupported header now')
        when 'grpc-status-details-bin'
          # TODO
          GrpcKit.logger.warn('grpc-status-details-bin is unsupported header now')
        else
          if RESERVED_HEADERS.include?(key) && !METADATA_ACCEPTABLE_HEADER.include?(key)
            return
          end

          headers.metadata[key] = val
        end
      end
    end
  end
end
