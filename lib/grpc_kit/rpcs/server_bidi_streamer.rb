# frozen_string_literal: true

require 'grpc_kit/rpcs'
require 'grpc_kit/calls/server_bidi_streamer'

module GrpcKit
  module Rpcs::Server
    class BidiStreamer < GrpcKit::Rpcs::ServerRpc
      # @param stream [GrpcKit::Stream::ServerStream]
      # @param metadata [Hash<String, String>]
      # @return [void]
      def invoke(stream, metadata: {})
        call = GrpcKit::Calls::Server::BidiStreamer.new(
          metadata: metadata,
          config: @config,
          stream: stream,
        )

        if @config.interceptor
          @config.interceptor.intercept(call) do |c|
            @handler.send(@config.ruby_style_method_name, c)
          end
        else
          @handler.send(@config.ruby_style_method_name, call)
        end

        stream.send_status
      end
    end
  end
end
