# frozen_string_literal: true

require 'grpc_kit/calls'

module GrpcKit
  module Calls::Client
    class ClientStreamer < GrpcKit::Calls::Call
      attr_reader :deadline, :service_name, :method_name
      attr_reader :metadata
      alias outgoing_metadata metadata

      def send_msg(data, last: false)
        raise 'No method error' if @restrict

        @stream.send_msg(data, last: last, metadata: outgoing_metadata)
      end

      def recv(last: false)
        raise 'No method error' if @restrict

        @stream.recv_msg(last: last)
      end

      def close_and_recv
        @stream.close_and_recv
      end
    end
  end
end
