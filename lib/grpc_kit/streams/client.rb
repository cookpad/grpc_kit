# frozen_string_literal: true

require 'grpc_kit/stream'
require 'grpc_kit/streams/send_buffer'
require 'grpc_kit/status_codes'

module GrpcKit
  module Streams
    class Client
      def initialize(session:, config:, authority:)
        @config = config
        @session = session
        @stream = nil
        @authority = authority
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
          stream = @session.start_request(GrpcKit::Streams::SendBuffer.new, headers)
          @stream = GrpcKit::Stream.new(protobuf: @config.protobuf, session: @session, stream: stream)
        end

        @stream.send(data, last: last, limit_size: @config.max_send_message_size)
        @session.run_once
      end

      def each(&block)
        unless @stream
          raise 'You should call `send` method to send data'
        end

        @stream.each(&block)
      end

      def recv(last: false)
        unless @stream
          raise 'You should call `send` method to send data'
        end

        data = @stream.recv(last: last, limit_size: @config.max_receive_message_size)

        if data.nil?
          check_status!
          raise StopIteration
        end

        data
      end

      def close_and_recv
        unless @stream
          raise 'You should call `send` method to send data'
        end

        unless @stream.end_write?
          @session.resume_data(@stream.stream_id)
        end

        @stream.end_write
        @session.start(@stream.stream_id)
        @stream.end_read

        check_status!

        data = []
        @stream.each { |d| data.push(d) }
        data
      end

      private

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
        hdrs = metadata.merge(headers).merge(
          ':method' => 'POST',
          ':scheme' => 'http',
          ':path' => @config.path,
          ':authority' => @authority,
          'te' => 'trailers',
          'content-type' => 'application/grpc',
          'user-agent' => "grpc-ruby/#{GrpcKit::VERSION} (grpc_kit)",
          'grpc-accept-encoding' => 'identity,deflate,gzip',
        )
        if timeout
          hdrs['grpc-timeout'] = timeout
        end

        hdrs
      end
    end
  end
end
