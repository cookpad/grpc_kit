# frozen_string_literal: true

require 'grpc_kit/grpc_time'

module GrpcKit
  module Session
    Headers = Struct.new(
      :metadata,
      :path,
      :grpc_encoding,
      :grpc_status,
      :status_message,
      :timeout,
      :method,
      :http_status,
    ) do

      RESERVED_HEADERS = [
        'content-type',
        'user-agent',
        'grpc-message-type',
        'grpc-encoding',
        'grpc-message',
        'grpc-status',
        'grpc-status-details-bin',
        'grpc-accept-encoding',
        'te'
      ].freeze

      IGNORE_HEADERS = [':method', ':scheme'].freeze

      METADATA_ACCEPTABLE_HEADER = %w[:authority user-agent].freeze
      def initialize
        super({}) # set metadata empty hash
      end

      def add(key, val)
        case key
        when ':path'
          self.path = val
        when ':status'
          self.http_status = Integer(val)
        when 'content-type'
          # self.grpc_encoding = val
        when 'grpc-encoding'
          self.grpc_encoding = val
        when 'grpc-status'
          self.grpc_status = val
        when 'grpc-timeout'
          self.timeout = GrpcTime.new(val)
        when 'grpc-message'
          self.status_message = val
        when 'grpc-status-details-bin'
          # TODO
          GrpcKit.logger.warn('grpc-status-details-bin is unsupported header now')
        else
          if IGNORE_HEADERS.include?(key)
            return
          end

          if RESERVED_HEADERS.include?(key) && !METADATA_ACCEPTABLE_HEADER.include?(key)
            return
          end

          metadata[key] = val
        end
      end
    end
  end
end
