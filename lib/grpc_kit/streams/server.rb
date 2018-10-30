# frozen_string_literal: true

require 'grpc_kit/stream'
require 'grpc_kit/status_codes'

module GrpcKit
  module Streams
    class Server
      # @params stream [GrpcKit::Session::Stream]
      # @params config [GrpcKit::MethodConfig]
      def initialize(stream:, config:)
        @stream = stream
        @config = config
        @sent_first_msg = false
      end

      def send_msg(data, protobuf, last: false, limit_size: nil)
        if last
          @stream.send_trailer # TODO: pass trailer metadata
        end

        buf =
          begin
            @config.protobuf.encode(data)
          rescue ArgumentError => e
            raise GrpcKit::Errors::Internal, "Error while encoding in server: #{e}"
          end
        @stream.send(buf, last: last, limit_size: limit_size)
        return if @sent_first_msg

        @stream.submit_response
        @sent_first_msg = true
      end

      def recv_msg(protobuf, last: false, limit_size: nil)
        buf = @stream.recv(last: last, limit_size: limit_size)
        raise StopIteration if buf.nil?

        begin
          @config.protobuf.decode(buf)
        rescue ArgumentError => e
          raise GrpcKit::Errors::Internal, "Error while decoding in Server: #{e}"
        end
      end

      def each
        loop { yield(recv) }
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
