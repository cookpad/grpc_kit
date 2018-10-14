# frozen_string_literal: false

require 'socket'
require 'grpc_kit/session/client'
require 'grpc_kit/session/duration'
require 'grpc_kit/rpcs'

module GrpcKit
  class Client
    def initialize(host, port, io: GrpcKit::IO::Basic, interceptors: [], timeout: nil)
      @host = host
      @port = port
      @authority = "#{host}:#{port}"
      @io = io
      @interceptors = interceptors
      @timeout =
        if timeout
          GrpcKit::Session::Duration.from_numeric(timeout)
        else
          nil
        end
    end

    def request_response(rpc, request, opts = {})
      GrpcKit.logger.info('Calling request_respose')

      rpc.config.interceptor.interceptors = @interceptors
      do_request(rpc, request, opts)
    end

    def client_streamer(rpc, opts = {})
      GrpcKit.logger.info('Calling client_streamer')
      rpc.config.interceptor.interceptors = @interceptors
      do_request(rpc, nil, opts)
    end

    def server_streamer(rpc, request, opts = {})
      GrpcKit.logger.info('Calling server_streamer')
      rpc.config.interceptor.interceptors = @interceptors
      do_request(rpc, request, opts)
    end

    def bidi_streamer(rpc, requests, opts = {})
      rpc.config.interceptor.interceptors = @interceptors
      GrpcKit.logger.info('Calling bidi_streamer')
    end

    private

    def do_request(rpc, request, **opts)
      sock = TCPSocket.new(@host, @port) # XXX

      session = GrpcKit::Session::Client.new(
        @io.new(sock, sock),
        rpc,
        authority: opts.delete(:authority) || @authority,
      )

      session.submit_settings([])
      t = opts.delete(:timeout) || @timeout
      rpc.invoke(session, request, timeout: t, **opts)
    end
  end
end
