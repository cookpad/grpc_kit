# frozen_string_literal: true

require 'grpc_kit/rpcs/base'

module GrpcKit
  module Rpcs
    module Client
      class ServerStreamer < Base
        def invoke(session, request, authority:, metadata: {}, timeout: nil, **opts)
          cs = GrpcKit::Streams::Client.new(path: @config.path, protobuf: @config.protobuf, session: session, authority: authority)
          call = GrpcKit::Rpcs::Call.new(metadata, @config.method_name, @config.service_name, cs)

          @config.interceptor.intercept(call) do |c|
            c.send_msg(request, last: true)
            c
          end
        end
      end
    end

    module Server
      class ServerStreamer < Base
        def invoke(stream, session)
          ss = GrpcKit::Streams::Server.new(stream: stream, protobuf: @config.protobuf, session: session)
          call = GrpcKit::Rpcs::Call.new(stream.headers.metadata, @config.method_name, @config.service_name, ss)

          if @config.interceptor
            @config.interceptor.intercept(call) do |c|
              request = c.recv(last: true)
              @handler.send(@config.ruby_style_method_name, request, c)
            end
          else
            request = call.recv(last: true)
            @handler.send(@config.ruby_style_method_name, request, call)
          end

          stream.end_write
        end
      end
    end
  end
end
