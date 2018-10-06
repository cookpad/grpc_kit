# frozen_string_literal: true

require 'grpc_kit/status_codes'

module GrpcKit
  module Errors
    # https://github.com/grpc/grpc/blob/23b5b1a5a9c7084c5b64d4998ee15af0f77bd589/doc/statuscodes.md
    class BadStatus < StandardError
      def initialize(code, message)
        super("#{code}:#{details}")
        @code = code
        @message = message
      end

      class Unimplemented < BadStatus
        def initialize(name)
          super(
            GrpcKit::StatusCodes::UNIMPLEMENTED,
            "Method not found at server: #{name}"
          )
        end
      end
    end
  end
end
