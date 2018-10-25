# frozen_string_literal: true

require 'grpc_kit/status_codes'

module GrpcKit
  module Errors
    # https://github.com/grpc/grpc/blob/23b5b1a5a9c7084c5b64d4998ee15af0f77bd589/doc/statuscodes.md

    def self.from_status_code(code, message)
      CODES.fetch(code).new(message)
    end

    class BadStatus < StandardError
      attr_reader :code, :reason, :grpc_message

      def initialize(code, reason)
        @code = code
        @reason = reason
        super("[#{GrpcKit::StatusCodes::CODE_NAME[code]}] #{reason}")
      end
    end

    class Unknown < BadStatus
      def initialize(mesage)
        super(GrpcKit::StatusCodes::UNKNOWN, mesage)
      end
    end

    class DeadlineExceeded < BadStatus
      def initialize(mesage)
        super(GrpcKit::StatusCodes::DEADLINE_EXCEEDED, mesage)
      end
    end

    class Unimplemented < BadStatus
      def initialize(mesage)
        super(GrpcKit::StatusCodes::UNIMPLEMENTED, mesage)
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
