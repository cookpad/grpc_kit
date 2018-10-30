# frozen_string_literal: true

require 'forwardable'
require 'grpc_kit/streams/packable'

module GrpcKit
  module Transports
    class ClientTransport
      include GrpcKit::Streams::Packable

      extend Forwardable

      delegate %i[stream_id end_write end_read end_write? end_read? close_remote? headers] => :@stream

      # @params session [GrpcKit::Session::Server|GrpcKit::Session::Client]
      def initialize(session:)
        @session = session
        @stream = nil # set later
      end

      def send_request(buf, headers)
        @stream = @session.send_request(buf, headers)
        self
      end

      def resume_if_need
        unless @stream.end_write?
          @session.resume_data(@stream.stream_id)
        end
      end

      def start
        @stream.end_write
        @session.start(@stream.stream_id)
        @stream.end_read
      end

      def wait_close
        # XXX: wait until half close (remote) to get grpc-status
        until @stream.close_remote?
          @session.run_once
        end
      end

      def run_once
        @session.run_once
      end

      def each
        loop do
          data = recv
          return if data.nil?

          yield(data)
        end
      end

      def write_data(buf, last: false)
        @stream.write_send_data(pack(buf), last: last)
      end

      def read_data(last: false)
        unpack(read(last: last))
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
