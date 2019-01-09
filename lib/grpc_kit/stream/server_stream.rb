# frozen_string_literal: true

require 'grpc_kit/errors'

module GrpcKit
  module Stream
    class ServerStream
      # @param transport [GrpcKit::transports::ServerTransport]
      def initialize(transport)
        @transport = transport
        @started = false
      end

      # @return [void]
      def invoke(rpc)
        rpc.invoke(self, metadata: @transport.recv_headers.metadata)
      rescue GrpcKit::Errors::BadStatus => e
        GrpcKit.logger.debug(e)
        send_status(status: e.code, msg: e.reason, metadata: {}) # TODO: metadata should be set
      rescue StandardError => e
        GrpcKit.logger.debug(e)
        send_status(status: GrpcKit::StatusCodes::UNKNOWN, msg: e.message, metadata: {})
      end

      # @param data [Object]
      # @param codec [GrpcKit::Codec]
      # @param last [Boolean]
      # @param limit_size [Integer]
      # @param initial_metadata [Hash<String,String>]
      # @param trailing_metadata [Hash<String,String>]
      # @return [void]
      def send_msg(data, codec, last: false, limit_size: nil, initial_metadata: {}, trailing_metadata: {})
        buf =
          begin
            codec.encode(data)
          rescue ArgumentError, TypeError => e
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
          start_response(buf, headers: initial_metadata)
        end
      end

      # @raise [StopIteration] when recving message finished
      # @param codec [GrpcKit::Codec]
      # @param last [Boolean]
      # @param limit_size [Integer]
      # @return [Object]
      def recv_msg(codec, last: false, limit_size: nil)
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

        begin
          codec.decode(buf)
        rescue ArgumentError => e
          raise GrpcKit::Errors::Internal, "Error while decoding in server: #{e}"
        end
      end

      # @param status [GrpcKit::StatusCodes::BadStatus, GrpcKit::StatusCodes::OK]
      # @param msg [String,nil]
      # @param metadata [Hash<String,String>]
      # @return [void]
      def send_status(data: nil, status: GrpcKit::StatusCodes::OK, msg: 'OK', metadata: {})
        t = build_trailers(status, msg, metadata)
        @transport.write_data(data, last: true) if data

        @transport.end_write
        if @started
          @transport.write_trailers(t)
        elsif data
          # first message with end flag
          start_response(nil, headers: t)
        else
          send_headers(trailers: t)
        end
      end

      private

      def send_headers(trailers: {})
        h = { ':status' => '200', 'content-type' => 'application/grpc' }
        h['accept-encoding'] = 'identity'

        @transport.submit_headers(h.merge(trailers))
        @started = true
      end

      def start_response(data = nil, headers: {})
        h = { ':status' => '200', 'content-type' => 'application/grpc' }
        h['accept-encoding'] = 'identity'

        @transport.write_data(data) if data
        @transport.start_response(h.merge(headers))
        @started = true
      end

      def build_trailers(status, msg, metadata)
        trailers = { 'grpc-status' => status.to_s }
        if msg
          trailers['grpc-message'] = msg
        end

        trailers.merge(metadata)
      end
    end
  end
end
