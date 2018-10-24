# frozen_string_literal: true

require 'forwardable'

require 'grpc_kit/stream'
require 'grpc_kit/status_codes'

module GrpcKit
  module Streams
    class Server
      extend Forwardable

      delegate %i[each recv] => :@stream

      def initialize(protobuf:, session:, stream:)
        @stream = GrpcKit::Stream.new(protobuf: protobuf, session: session, stream: stream)
        @sent_first_msg = false
      end

      def send_msg(data, last: false)
        if last
          @stream.send_trailer # TODO: pass trailer metadata
        end

        @stream.send(data, last: last)
        return if @sent_first_msg

        @stream.submit_response
        @sent_first_msg = true
      end

      def send_status(status: GrpcKit::StatusCodes::INTERNAL, msg: nil, metadata: {})
        @stream.send_trailer(status: status, msg: msg, metadata: metadata)
        return if @sent_first_msg

        @stream.submit_response(piggyback_trailer: true)
        @sent_first_msg = true
      end
    end
  end
end
