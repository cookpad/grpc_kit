# frozen_string_literal: true

require 'grpc_kit/streams/send_buffer'
require 'grpc_kit/status_codes'

module GrpcKit
  module Streams
    class Client
      # @params session [GrpcKit::Session::Client]
      # @params config [GrpcKit::MethodConfig]
      # @params authority [String]
      def initialize(session:, config:, authority:)
        @config = config
        @session = session
        @authority = authority
        @stream = nil
      end

      def send_msg(data, metadata: {}, timeout: nil, last: false)
        if @stream
          # unless metadata.empty?
          #   raise 'You can attach metadata at first send_msg' # XXX
          # end

          unless @stream.end_write?
            @session.resume_data(@stream.stream_id)
          end
        else
          headers = build_headers(metadata: metadata, timeout: timeout)
          @stream = @session.start_request(GrpcKit::Streams::SendBuffer.new, headers)
        end

        buf =
          begin
            @config.protobuf.encode(data)
          rescue ArgumentError => e
            raise GrpcKit::Errors::Internal, "Error while encoding in client: #{e}"
          end
        @stream.write_data(buf, last: last, limit_size: @config.max_send_message_size)
        @session.run_once
      end

      def each
        validate_if_request_start!

        loop { yield(do_recv) }
      end

      def recv_msg(last: false)
        validate_if_request_start!

        do_recv(last: last)
      end

      def close_and_recv
        validate_if_request_start!

        unless @stream.end_write?
          @session.resume_data(@stream.stream_id)
        end

        @stream.end_write
        @session.start(@stream.stream_id)
        @stream.end_read

        check_status!

        data = []
        loop { data.push(do_recv) }
        data
      end

      private

      def validate_if_request_start!
        unless @stream
          raise 'You should call `send_msg` method to send data'
        end
      end

      def do_recv(last: false)
        buf = @stream.read_data(last: last, limit_size: @config.max_receive_message_size)
        if buf.nil?
          check_status!
          raise StopIteration
        end

        begin
          @config.protobuf.decode(buf)
        rescue ArgumentError => e
          raise GrpcKit::Errors::Internal, "Error while decoding in Client: #{e}"
        end
      end

      def check_status!
        # XXX: wait until half close (remote) to get grpc-status
        until @stream.close_remote?
          @session.run_once
        end

        if @stream.headers.grpc_status != GrpcKit::StatusCodes::OK
          raise GrpcKit::Errors.from_status_code(@stream.headers.grpc_status, @stream.headers.status_message)
        else
          GrpcKit.logger.debug('request is success')
        end
      end

      def build_headers(metadata: {}, timeout: nil, **headers)
        # TODO: an order of Headers is important?
        hdrs = {
          ':method' => 'POST',
          ':scheme' => 'http',
          ':path' => @config.path,
          ':authority' => @authority,
          'grpc-timeout' => timeout,
          'te' => 'trailers',
          'content-type' => 'application/grpc',
          'user-agent' => "grpc-ruby/#{GrpcKit::VERSION} (grpc_kit)",
          'grpc-accept-encoding' => 'identity,deflate,gzip',
        }.merge(headers)

        metadata.each do |k, v|
          if k.start_with?('grpc-')
            # https://github.com/grpc/grpc/blob/ffac9d90b18cb076b1c952faa55ce4e049cbc9a6/doc/PROTOCOL-HTTP2.md
            GrpcKit.logger.info("metadata name wich starts with 'grpc-' is reserved for future GRPC")
          else
            hdrs[k] = v
          end
        end

        hdrs.compact
      end
    end
  end
end
