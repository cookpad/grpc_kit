# frozen_string_literal: true

require 'forwardable'

require 'grpc_kit/stream'
require 'grpc_kit/status_codes'

module GrpcKit
  module Streams
    class Server
      extend Forwardable

      delegate %i[each recv] => :@stream

      def initialize(stream:, session:, config:)
        @stream = GrpcKit::Stream.new(protobuf: config.protobuf, session: session, stream: stream)
        @config = config
        @sent_first_msg = false
      end

      def send_msg(data, last: false)
        if last
          @stream.send_trailer # TODO: pass trailer metadata
        end

        @stream.send(data, last: last, limit_size: @config.max_send_message_size)
        return if @sent_first_msg

        @stream.submit_response
        @sent_first_msg = true
      end

      def recv(last: false)
        data = @stream.recv(last: last, limit_size: @config.max_receive_message_size)
        raise StopIteration if data.nil?

        data
      end

      def send_trailer
        @stream.send_trailer # TODO: pass trailer metadata
        @stream.end_write
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
