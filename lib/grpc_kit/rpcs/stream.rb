# frozen_string_literal: true

require 'grpc_kit/rpcs/packable'

module GrpcKit
  module Rpcs
    class Stream
      include GrpcKit::Rpcs::Packable

      def initialize(stream, handler:, method_name:, protobuf:)
        @stream = stream
        @handler = handler
        @method_name = method_name
        @protobuf = protobuf
        @sent_first_msg = false
      end

      def send_msg(data)
        resp = @protobuf.encode(data)
        @stream.write(pack(resp))

        return if @sent_first_msg

        @stream.submit_response(
          ':status' => '200',
          'content-type' => 'application/grpc',
          'accept-encoding' => 'identity,gzip',
        )
        @sent_first_msg = true
      end
    end
  end
end
