# frozen_string_literal: true

require 'grpc_kit/rpcs/base'

module GrpcKit
  module Rpcs
    module Client
      class ClientStreamer < Base
        def invoke(session, _data, metadata: {}, **opts)
          cs = GrpcKit::Streams::Client.new(path: @config.path, protobuf: @config.protobuf, session: session)
          context = GrpcKit::Rpcs::Context.new(metadata, @config.method_name, @config.service_name, cs)

          if @config.interceptor
            @config.interceptor.intercept(context) do |s|
              s
            end
          else
            cs
          end
        end
      end
    end

    module Server
      class ClientStreamer < Base
        def invoke(stream, session)
          ss = GrpcKit::Streams::Server.new(stream: stream, protobuf: @config.protobuf, session: session)
          # TODO: create object which is used by only ServerSteamer
          call = GrpcKit::Rpcs::Context.new(
            stream.headers.metadata,
            @config.method_name,
            @config.service_name,
            ss,
          )

          if @config.interceptor
            @config.interceptor.intercept(call) do |s|
              resp = @handler.send(@config.ruby_style_method_name, s)
              s.send_msg(resp, last: true)
            end
          else
            resp = @handler.send(@config.ruby_style_method_name, ss)
            ss.send_msg(resp, last: true)
          end
        end
      end
    end
  end
end
