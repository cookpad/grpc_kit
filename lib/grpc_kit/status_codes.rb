# frozen_string_literal: true

module GrpcKit
  module StatusCodes
    OK                  = '0'
    CANCELLED           = '1'
    UNKNOWN             = '2'
    INVALID_ARGUMENT    = '3'
    DEADLINE_EXCEEDED   = '4'
    NOT_FOUND           = '5'
    ALREADY_EXISTS      = '6'
    PERMISSION_DENIED   = '7'
    RESOURCE_EXHAUSTED  = '8'
    FAILED_PRECONDITION = '9'
    ABORTED             = '10'
    OUT_OF_RANGE        = '11'
    UNIMPLEMENTED       = '12'
    INTERNAL            = '13'
    UNAVAILABLE         = '14'
    DATA_LOSS           = '15'
    UNAUTHENTICATED     = '16'
    DO_NOT_USE          = '-1'

    CODE_NAME = {
      OK => 'OK',
      CANCELLED => 'CANCELLED',
      UNKNOWN => 'UNKNOWN',
      INVALID_ARGUMENT => 'INVALID_ARGUMENT',
      DEADLINE_EXCEEDED => 'DEADLINE_EXCEEDED',
      NOT_FOUND => 'NOT_FOUND',
      ALREADY_EXISTS => 'ALREADY_EXISTS',
      PERMISSION_DENIED => 'PERMISSION_DENIED',
      RESOURCE_EXHAUSTED => 'RESOURCE_EXHAUSTED',
      FAILED_PRECONDITION => 'FAILED_PRECONDITION',
      ABORTED => 'ABORTED',
      OUT_OF_RANGE => 'OUT_OF_RANGE',
      UNIMPLEMENTED => 'UNIMPLEMENTED',
      INTERNAL => 'INTERNAL',
      UNAVAILABLE => 'UNAVAILABLE',
      DATA_LOSS => 'DATA_LOSS',
      UNAUTHENTICATED => 'UNAUTHENTICATED',
      DO_NOT_USE => 'DO_NOT_USE',
    }.freeze
  end
end
