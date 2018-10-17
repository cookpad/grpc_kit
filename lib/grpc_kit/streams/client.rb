# frozen_string_literal: true

require 'grpc_kit/stream'
require 'grpc_kit/streams/send_buffer'

module GrpcKit
  module Streams
    class Client
      def initialize(path:, protobuf:, session:)
        @path = path
        @session = session
        @protobuf = protobuf
        @stream = nil
      end

      def send(data, metadata: {}, timeout: nil, last: false)
        if @stream
          unless @stream.end_write?
            @session.resume_data(@stream.stream_id)
          end
        else
          stream = @session.start_request(GrpcKit::Streams::SendBuffer.new, metadata: metadata, timeout: timeout, path: @path)
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
    end
  end
end
