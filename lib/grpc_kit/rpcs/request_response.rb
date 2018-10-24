# frozen_string_literal: true

require 'grpc_kit/rpcs/base'
require 'grpc_kit/status_codes'

module GrpcKit
  module Rpcs
    module Client
      class RequestResponse < Base
        def invoke(session, request, authority:, metadata: {}, timeout: nil, **opts)
          cs = GrpcKit::Streams::Client.new(path: @config.path, protobuf: @config.protobuf, session: session, authority: authority)

          call = GrpcKit::Rpcs::Call.new(metadata, @config.method_name, @config.service_name, cs)
          @config.interceptor.intercept(request, call, metadata) do |r, c, m|
            if timeout
              # XXX: when timeout.to_timeout is 0
              Timeout.timeout(timeout.to_timeout, GrpcKit::Errors::DeadlineExceeded) do
                c.send_msg(r, timeout: timeout.to_s, metadata: m, last: true)
                c.recv(last: true)
              end
            else
              c.send_msg(r, metadata: m, last: true)
              c.recv(last: true)
            end
          end
        end
      end
    end

    module Server
      class RequestResponse < Base
        def invoke(stream, session)
          ss = GrpcKit::Streams::Server.new(stream: stream, protobuf: @config.protobuf, session: session)
          call = GrpcKit::Rpcs::Call.new(stream.headers.metadata, @config.method_name, @config.service_name, ss)

          begin
            do_invoke(ss, call)
          rescue GrpcKit::Errors::BadStatus => e
            ss.send_status(status: e.code, msg: e.grpc_message, metadata: {}) # TODO: metadata should be set
          rescue StandardError => e
            ss.send_status(status: GrpcKit::StatusCodes::UNKNOWN, msg: e.message, metadata: {})
          end
        end

        private

        def do_invoke(ss, call)
          request = ss.recv(last: true)

          resp =
            if @config.interceptor
              @config.interceptor.intercept(request, call) do |req, c|
                @handler.send(@config.ruby_style_method_name, req, c)
              end
            else
              @handler.send(@config.ruby_style_method_name, request, call)
            end

          ss.send_msg(resp, last: true)
        end
      end
    end
  end
end
