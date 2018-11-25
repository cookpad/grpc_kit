# frozen_string_literal: true

require 'grpc_kit/status_codes'

module GrpcKit
  module Errors
    # https://github.com/grpc/grpc/blob/23b5b1a5a9c7084c5b64d4998ee15af0f77bd589/doc/statuscodes.md

    # @param code [String] GrpcKit::StatusCodes's value
    # @param message [String]
    # @return [GrpcKit::Errors::BadStatus]
    def self.from_status_code(code, message)
      CODES.fetch(code).new(message)
    end

    class BadStatus < StandardError
      # @return [String]
      attr_reader :code

      # @return [String]
      attr_reader :reason

      # @param code [String] GrpcKit::StatusCodes's value
      # @param reason [String]
      def initialize(code, reason)
        @code = code
        @reason = reason
        super("[#{GrpcKit::StatusCodes::CODE_NAME[code]}] #{reason}")
      end
    end

    class Unknown < BadStatus
      # @param message [String]
      def initialize(message)
        super(GrpcKit::StatusCodes::UNKNOWN, message)
      end
    end

    class DeadlineExceeded < BadStatus
      # @param message [String]
      def initialize(message)
        super(GrpcKit::StatusCodes::DEADLINE_EXCEEDED, message)
      end
    end

    class Unimplemented < BadStatus
      # @param message [String]
      def initialize(message)
        super(GrpcKit::StatusCodes::UNIMPLEMENTED, message)
      end
    end

    class ResourceExhausted < BadStatus
      # @param message [String]
      def initialize(message)
        super(GrpcKit::StatusCodes::RESOURCE_EXHAUSTED, message)
      end
    end

    class Internal < BadStatus
      # @param message [String]
      def initialize(message)
        super(GrpcKit::StatusCodes::INTERNAL, message)
      end
    end

    CODES = {
      # GrpcKit::StatusCode::OK                  => 'OK',
      # GrpcKit::StatusCode::CANCELLED           => 'CANCELLED',
      GrpcKit::StatusCodes::UNKNOWN             => Unknown,
      # GrpcKit::StatusCode::INVALID_ARGUMENT    => 'INVALID_ARGUMENT',
      GrpcKit::StatusCodes::DEADLINE_EXCEEDED   => DeadlineExceeded,
      # GrpcKit::StatusCode::NOT_FOUND           => 'NOT_FOUND',
      # GrpcKit::StatusCode::ALREADY_EXISTS      => 'ALREADY_EXISTS',
      # GrpcKit::StatusCode::PERMISSION_DENIED   => 'PERMISSION_DENIED',
      GrpcKit::StatusCodes::RESOURCE_EXHAUSTED  => ResourceExhausted,
      # GrpcKit::StatusCode::FAILED_PRECONDITION => 'FAILED_PRECONDITION',
      # GrpcKit::StatusCode::ABORTED             => 'ABORTED',
      # GrpcKit::StatusCode::OUT_OF_RANGE        => 'OUT_OF_RANGE',
      GrpcKit::StatusCodes::UNIMPLEMENTED       => Unimplemented,
      GrpcKit::StatusCodes::INTERNAL            => Internal,
      # GrpcKit::StatusCode::UNAVAILABLE         => 'UNAVAILABLE',
      # GrpcKit::StatusCode::DATA_LOSS           => 'DATA_LOSS',
      # GrpcKit::StatusCode::UNAUTHENTICATED     => 'UNAUTHENTICATED',
      # GrpcKit::StatusCode::DO_NOT_USE          => 'DO_NOT_USE',
    }.freeze
  end
end
