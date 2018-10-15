# frozen_string_literal: true

require 'grpc_kit/rpcs/base'

module GrpcKit
  module Rpcs
    module Client
      class ServerStreamer < Base
        def invoke(session, data, metadata: {}, **opts)
          cs = GrpcKit::ClientStream.new(path: @config.path, protobuf: @config.protobuf, session: session)
          context = GrpcKit::Rpcs::Context.new(metadata, @config.method_name, @config.service_name, cs)

          if @config.interceptor
            @config.interceptor.intercept(context) do |s|
              s.send(data, end_stream: true)
              s
            end
          else
            cs.send(data, end_stream: true)
            cs
          end
        end
      end
    end

    module Server
      class ServerStreamer < Base
        def invoke(stream)
          ss = GrpcKit::ServerStream.new(stream: stream, protobuf: @config.protobuf)
          # TODO: create object which is used by only ServerSteamer
          call = GrpcKit::Rpcs::Context.new(
            stream.headers.metadata,
            @config.method_name,
            @config.service_name,
            ss,
          )

          if @config.interceptor
            @config.interceptor.intercept(call) do |s|
              request = s.recv
              @handler.send(@config.ruby_style_method_name, request, s)
            end
          else
            request = ss.recv
            @handler.send(@config.ruby_style_method_name, request, ss)
          end

          stream.end_write
        end
      end
    end
  end
end
