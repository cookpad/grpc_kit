# frozen_string_literal: true

require 'grpc_kit/status_codes'

module GrpcKit
  module Errors
    # https://github.com/grpc/grpc/blob/23b5b1a5a9c7084c5b64d4998ee15af0f77bd589/doc/statuscodes.md

    def self.from_error_code(code, message)
      CODES[code].new(message)
    end

    class BadStatus < StandardError
      attr_reader :code

      def initialize(code, message)
        super("#{GrpcKit::StatusCodes::CODE_NAME[code]} #{message}")
        @code = code
        @message = message
      end
    end

    class DeadlienExceeded < BadStatus
      def initialize(msg)
        super(
          GrpcKit::StatusCodes::DEADLINE_EXCEEDED,
          msg.to_s,
          # "Deadline expires before server returns status: #{msg}"
        )
      end
    end

    class Unimplemented < BadStatus
      def initialize(name)
        super(
          GrpcKit::StatusCodes::UNIMPLEMENTED,
          "Method not found at server: #{name}"
        )
      end
    end

    CODES = {
      # GrpcKit::StatusCode::OK                  => 'OK',
      # GrpcKit::StatusCode::CANCELLED           => 'CANCELLED',
      # GrpcKit::StatusCode::UNKNOWN             => 'UNKNOWN',
      # GrpcKit::StatusCode::INVALID_ARGUMENT    => 'INVALID_ARGUMENT',
      # GrpcKit::StatusCode::DEADLINE_EXCEEDED   => 'DEADLINE_EXCEEDED',
      # GrpcKit::StatusCode::NOT_FOUND           => 'NOT_FOUND',
      # GrpcKit::StatusCode::ALREADY_EXISTS      => 'ALREADY_EXISTS',
      # GrpcKit::StatusCode::PERMISSION_DENIED   => 'PERMISSION_DENIED',
      # GrpcKit::StatusCode::RESOURCE_EXHAUSTED  => 'RESOURCE_EXHAUSTED',
      # GrpcKit::StatusCode::FAILED_PRECONDITION => 'FAILED_PRECONDITION',
      # GrpcKit::StatusCode::ABORTED             => 'ABORTED',
      # GrpcKit::StatusCode::OUT_OF_RANGE        => 'OUT_OF_RANGE',
      GrpcKit::StatusCodes::UNIMPLEMENTED       => Unimplemented,
      # GrpcKit::StatusCode::INTERNAL            => 'INTERNAL',
      # GrpcKit::StatusCode::UNAVAILABLE         => 'UNAVAILABLE',
      # GrpcKit::StatusCode::DATA_LOSS           => 'DATA_LOSS',
      # GrpcKit::StatusCode::UNAUTHENTICATED     => 'UNAUTHENTICATED',
      # GrpcKit::StatusCode::DO_NOT_USE          => 'DO_NOT_USE',
    }.freeze
  end
end
