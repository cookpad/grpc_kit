# frozen_string_literal: true

require 'grpc_kit/status_codes'

module GrpcKit
  module Streams
    class ServerStream
      # @params transport [GrpcKit::transports::ServerTransport]
      def initialize(transport)
        @transport = transport
        @sent_first_msg = false
      end

      def invoke(rpc)
        rpc.invoke(self, metadata: @transport.recv_headers.metadata)
      rescue GrpcKit::Errors::BadStatus => e
        GrpcKit.logger.debug(e)
        send_status(status: e.code, msg: e.reason, metadata: {}) # TODO: metadata should be set
      rescue StandardError => e
        GrpcKit.logger.debug(e)
        send_status(status: GrpcKit::StatusCodes::UNKNOWN, msg: e.message, metadata: {})
      end

      def send_msg(data, protobuf, last: false, limit_size: nil, initial_metadata: {}, trailing_metadata: {})
        if last
          send_trailer(metadata: trailing_metadata)
        end

        buf =
          begin
            protobuf.encode(data)
          rescue ArgumentError => e
            raise GrpcKit::Errors::Internal, "Error while encoding in server: #{e}"
          end

        if limit_size && buf.bytesize > limit_size
          raise GrpcKit::Errors::ResourceExhausted, "Sending message is too large: send=#{req.bytesize}, max=#{limit_size}"
        end

        @transport.write_data(buf, last: last)
        return if @sent_first_msg

        send_response(initial_metadata)
        @sent_first_msg = true
      end

      def recv_msg(protobuf, last: false, limit_size: nil)
        data = @transport.read_data(last: last)

        raise StopIteration if data.nil?

        compressed, size, buf = *data

        unless size == buf.size
          raise "inconsistent data: #{buf}"
        end

        if limit_size && size > limit_size
          raise GrpcKit::Errors::ResourceExhausted, "Receving message is too large: recevied=#{size}, max=#{limit_size}"
        end

        if compressed
          raise 'compress option is unsupported'
        end

        raise StopIteration if buf.nil?

        begin
          protobuf.decode(buf)
        rescue ArgumentError => e
          raise GrpcKit::Errors::Internal, "Error while decoding in Server: #{e}"
        end
      end

      def each
        loop { yield(recv) }
      end

      def send_status(status: GrpcKit::StatusCodes::OK, msg: nil, metadata: {})
        send_trailer(status: status, msg: msg, metadata: metadata)
        return if @sent_first_msg

        send_response({})
        @sent_first_msg = true
      end

      def send_trailer(status: GrpcKit::StatusCodes::OK, msg: nil, metadata: {})
        trailer = { 'grpc-status' => status.to_s }
        if msg
          trailer['grpc-message'] = msg
        end

        @transport.write_trailers_data(trailer.merge(metadata))
      end

      def send_response(metadata = {})
        h = { ':status' => '200', 'content-type' => 'application/grpc' }
        h['accept-encoding'] = 'identity'
        @transport.send_response(h.merge(metadata))
      end
    end
  end
end
