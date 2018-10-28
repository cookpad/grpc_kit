# frozen_string_literal: true

require 'grpc_kit/rpcs/base'
require 'grpc_kit/calls/server_client_streamer'
require 'grpc_kit/calls/client_client_streamer'

module GrpcKit
  module Rpcs
    module Client
      class ClientStreamer < Base
        def invoke(stream, _request, metadata: {}, timeout: nil)
          call = GrpcKit::Calls::Client::ClientStreamer.new(metadata: metadata, config: @config, timeout: timeout, stream: stream)
          @config.interceptor.intercept(call, metadata) do |s|
            s
          end
        end
      end
    end

    module Server
      class ClientStreamer < Base
        def invoke(stream)
          ss = GrpcKit::Streams::Server.new(stream: stream, config: @config)
          call = GrpcKit::Calls::Server::ClientStreamer.new(metadata: stream.headers.metadata, config: @config, stream: ss)

          if @config.interceptor
            @config.interceptor.intercept(call) do |c|
              resp = @handler.send(@config.ruby_style_method_name, c)
              c.send_msg(resp, last: true)
            end
          else
            resp = @handler.send(@config.ruby_style_method_name, call)
            call.send_msg(resp, last: true)
          end
        end
      end
    end
  end
end
