# frozen_string_literal: true

require 'forwardable'

require 'grpc_kit/stream'

module GrpcKit
  module Streams
    class Server
      extend Forwardable

      delegate %i[each recv] => :@stream

      def initialize(protobuf:, session:, stream:)
        @protobuf = protobuf
        @session = session
        @stream = GrpcKit::Stream.new(protobuf: @protobuf, session: @session, stream: stream)
        @sent_first_msg = false
      end

      def send_msg(data, last: false)
        @stream.send(data, last: last)

        return if @sent_first_msg

        @session.submit_response(
          @stream.stream_id,
          ':status' => '200',
          'content-type' => 'application/grpc',
          'accept-encoding' => 'identity',
        )
        @sent_first_msg = true
      end
    end
  end
end
