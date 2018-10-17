# frozen_string_literal: true

require 'grpc_kit/stream'
require 'grpc_kit/streams/send_buffer'

module GrpcKit
  module Streams
    class Client
      def initialize(path:, protobuf:, session:, authority:)
        @path = path
        @session = session
        @protobuf = protobuf
        @stream = nil
        @authority = authority
      end

      def send_msg(data, metadata: {}, timeout: nil, last: false)
        if @stream
          unless @stream.end_write?
            @session.resume_data(@stream.stream_id)
          end
        else
          headers = build_headers(metadata: metadata, timeout: timeout)
          stream = @session.start_request(GrpcKit::Streams::SendBuffer.new, headers)
          @stream = GrpcKit::Stream.new(protobuf: @protobuf, session: @session, stream: stream)
        end

        @stream.send(data, last: last)
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

        @stream.recv(last: last)
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

        data = []
        @stream.each { |d| data.push(d) }
        data
      end

      private

      def build_headers(metadata: {}, timeout: nil, **headers)
        hdrs = metadata.merge(headers).merge(
          ':method' => 'POST',
          ':scheme' => 'http',
          ':path' => @path,
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
