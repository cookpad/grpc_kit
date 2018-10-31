# frozen_string_literal: true

require 'grpc_kit/status_codes'

module GrpcKit
  module Stream
    class ServerStream
      # @params transport [GrpcKit::transports::ServerTransport]
      def initialize(transport)
        @transport = transport
        @started = false
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
        buf =
          begin
            protobuf.encode(data)
          rescue ArgumentError => e
            raise GrpcKit::Errors::Internal, "Error while encoding in server: #{e}"
          end

        if limit_size && buf.bytesize > limit_size
          raise GrpcKit::Errors::ResourceExhausted, "Sending message is too large: send=#{req.bytesize}, max=#{limit_size}"
        end

        if last
          send_status(data: buf, metadata: trailing_metadata)
        elsif @started
          @transport.write_data(buf)
        else
          start_response(buf, metadata: initial_metadata)
        end
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
          raise GrpcKit::Errors::Internal, "Error while decoding in server: #{e}"
        end
      end

      def each
        loop { yield(recv) }
      end

      def send_status(data: nil, status: GrpcKit::StatusCodes::OK, msg: nil, metadata: {})
        @transport.write_data(data, last: true) if data
        write_trailers(status, msg, metadata)

        start_response unless @started
      end

      private

      def start_response(data = nil, metadata: {})
        h = { ':status' => '200', 'content-type' => 'application/grpc' }
        h['accept-encoding'] = 'identity'

        @transport.write_data(data) if data
        @transport.start_response(h.merge(metadata))
        @started = true
      end

      def write_trailers(status, msg, metadata)
        trailers = { 'grpc-status' => status.to_s }
        if msg
          trailers['grpc-message'] = msg
        end

        @transport.write_trailers(trailers.merge(metadata))
      end
    end
  end
end
