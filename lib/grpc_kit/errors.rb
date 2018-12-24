# frozen_string_literal: true

require 'grpc_kit/status_codes'

module GrpcKit
  module Errors
    # https://github.com/grpc/grpc/blob/23b5b1a5a9c7084c5b64d4998ee15af0f77bd589/doc/statuscodes.md

    # @param code [String] GrpcKit::StatusCodes's value
    # @param message [String]
    # @return [GrpcKit::Errors::BadStatus]
    def self.from_status_code(code, message)
      if code == GrpcKit::StatusCodes::OK
        raise ArgumentError, 'Status OK is not an error'
      end

      error_class = CODES[code]
      if error_class
        error_class.new(message)
      else
        GrpcKit::Errors::Unknown.new("Received unknown code: code=#{code}\n #{message}")
      end
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

    class Cancelled < BadStatus
      # @param message [String]
      def initialize(message)
        super(GrpcKit::StatusCodes::CANCELLED, message)
      end
    end

    class Unknown < BadStatus
      # @param message [String]
      def initialize(message)
        super(GrpcKit::StatusCodes::UNKNOWN, message)
      end
    end

    class InvalidArgument < BadStatus
      # @param message [String]
      def initialize(message)
        super(GrpcKit::StatusCodes::INVALID_ARGUMENT, message)
      end
    end

    class DeadlineExceeded < BadStatus
      # @param message [String]
      def initialize(message)
        super(GrpcKit::StatusCodes::DEADLINE_EXCEEDED, message)
      end
    end

    class NotFound < BadStatus
      # @param message [String]
      def initialize(message)
        super(GrpcKit::StatusCodes::NOT_FOUND, message)
      end
    end

    class AlreadyExists < BadStatus
      # @param message [String]
      def initialize(message)
        super(GrpcKit::StatusCodes::ALREADY_EXISTS, message)
      end
    end

    class PermissionDenied < BadStatus
      # @param message [String]
      def initialize(message)
        super(GrpcKit::StatusCodes::PERMISSION_DENIED, message)
      end
    end

    class ResourceExhausted < BadStatus
      # @param message [String]
      def initialize(message)
        super(GrpcKit::StatusCodes::RESOURCE_EXHAUSTED, message)
      end
    end

    class FailedPrecondition < BadStatus
      # @param message [String]
      def initialize(message)
        super(GrpcKit::StatusCodes::FAILED_PRECONDITION, message)
      end
    end

    class Aborted < BadStatus
      # @param message [String]
      def initialize(message)
        super(GrpcKit::StatusCodes::ABORTED, message)
      end
    end

    class OutOfRange < BadStatus
      # @param message [String]
      def initialize(message)
        super(GrpcKit::StatusCodes::OUT_OF_RANGE, message)
      end
    end

    class Unimplemented < BadStatus
      # @param message [String]
      def initialize(message)
        super(GrpcKit::StatusCodes::UNIMPLEMENTED, message)
      end
    end

    class Internal < BadStatus
      # @param message [String]
      def initialize(message)
        super(GrpcKit::StatusCodes::INTERNAL, message)
      end
    end

    class Unavailable < BadStatus
      # @param message [String]
      def initialize(message)
        super(GrpcKit::StatusCodes::UNAVAILABLE, message)
      end
    end

    class DataLoss < BadStatus
      # @param message [String]
      def initialize(message)
        super(GrpcKit::StatusCodes::DATA_LOSS, message)
      end
    end

    class Unauthenticated < BadStatus
      # @param message [String]
      def initialize(message)
        super(GrpcKit::StatusCodes::UNAUTHENTICATED, message)
      end
    end

    class DoNotUse < BadStatus
      # @param message [String]
      def initialize(message)
        super(GrpcKit::StatusCodes::DO_NOT_USE, message)
      end
    end

    CODES = {
      GrpcKit::StatusCodes::CANCELLED => Cancelled,
      GrpcKit::StatusCodes::UNKNOWN => Unknown,
      GrpcKit::StatusCodes::INVALID_ARGUMENT => InvalidArgument,
      GrpcKit::StatusCodes::DEADLINE_EXCEEDED => DeadlineExceeded,
      GrpcKit::StatusCodes::NOT_FOUND => NotFound,
      GrpcKit::StatusCodes::ALREADY_EXISTS => AlreadyExists,
      GrpcKit::StatusCodes::PERMISSION_DENIED => PermissionDenied,
      GrpcKit::StatusCodes::RESOURCE_EXHAUSTED => ResourceExhausted,
      GrpcKit::StatusCodes::FAILED_PRECONDITION => FailedPrecondition,
      GrpcKit::StatusCodes::ABORTED => Aborted,
      GrpcKit::StatusCodes::OUT_OF_RANGE => OutOfRange,
      GrpcKit::StatusCodes::UNIMPLEMENTED => Unimplemented,
      GrpcKit::StatusCodes::INTERNAL => Internal,
      GrpcKit::StatusCodes::UNAVAILABLE => Unavailable,
      GrpcKit::StatusCodes::DATA_LOSS => DataLoss,
      GrpcKit::StatusCodes::UNAUTHENTICATED => Unauthenticated,
      GrpcKit::StatusCodes::DO_NOT_USE => DoNotUse,
    }.freeze
  end
end
