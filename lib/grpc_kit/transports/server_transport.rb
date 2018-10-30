# frozen_string_literal: true

require 'grpc_kit/streams/packable'

module GrpcKit
  module Transports
    class ServerTransport
      include GrpcKit::Streams::Packable

      # @params session [GrpcKit::Session::Server|GrpcKit::Session::Client]
      # @params stream [GrpcKit::Session::Stream] primitive H2 stream id
      def initialize(session:, stream:, config: nil)
        @session = session
        @stream = stream
        @config = config
      end

      def each
        loop do
          data = recv
          return if data.nil?

          yield(data)
        end
      end

      def send_response(headers)
        @session.submit_response(@stream.stream_id, headers)
      end

      def write_data(buf, last: false)
        @stream.write_send_data(pack(buf), last: last)
      end

      def read_data(last: false)
        unpack(read(last: last))
      end

      def write_trailers_data(trailer)
        @stream.write_trailers_data(trailer)
        @stream.end_write
      end

      private

      def read(last: false)
        loop do
          data = @stream.read_recv_data(last: last)
          return data unless data.empty?

          if @stream.close_remote?
            # it do not receive data which we need, it may receive invalid grpc-status
            unless @stream.end_read?
              return nil
            end

            return nil
          end

          @session.run_once
        end
      end
    end
  end
end
