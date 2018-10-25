# frozen_string_literal: true

require 'grpc_kit/rpcs/base'

module GrpcKit
  module Rpcs
    module Client
      class ClientStreamer < Base
        def invoke(session, _request, authority:, metadata: {}, timeout: nil, **opts)
          cs = GrpcKit::Streams::Client.new(config: @config, session: session, authority: authority)
          call = GrpcKit::Rpcs::Call.new(metadata, @config.method_name, @config.service_name, cs)
          @config.interceptor.intercept(call, metadata) do |s|
            s
          end
        end
      end
    end

    module Server
      class ClientStreamer < Base
        def invoke(stream, session)
          ss = GrpcKit::Streams::Server.new(stream: stream, session: session, config: @config)
          call = GrpcKit::Rpcs::Call.new(stream.headers.metadata, @config.method_name, @config.service_name, ss)

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
