# frozen_string_literal: true

require 'grpc_kit/rpcs/base'

module GrpcKit
  module Rpcs
    module Client
      class ServerStreamer < Base
        def invoke(session, data, metadata: {}, **opts)
          cs = GrpcKit::Streams::Client.new(path: @config.path, protobuf: @config.protobuf, session: session)
          context = GrpcKit::Rpcs::Context.new(metadata, @config.method_name, @config.service_name, cs)

          if @config.interceptor
            @config.interceptor.intercept(context) do |s|
              s.send(data, last: true)
              s
            end
          else
            cs.send(data, last: true)
            cs
          end
        end
      end
    end

    module Server
      class ServerStreamer < Base
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
              request = s.recv(last: true)
              @handler.send(@config.ruby_style_method_name, request, s)
            end
          else
            request = ss.recv(last: true)
            @handler.send(@config.ruby_style_method_name, request, ss)
          end

          stream.end_write
        end
      end
    end
  end
end
