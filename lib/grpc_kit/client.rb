# frozen_string_literal: false

require 'grpc_kit/grpc_time'
require 'grpc_kit/session/io'
require 'grpc_kit/session/client_session'
require 'grpc_kit/stream/client_stream'
require 'grpc_kit/transport/client_transport'

module GrpcKit
  class Client
    def initialize(sock, authority: nil, interceptors: [], timeout: nil)
      @sock = sock
      @authority =
        if authority
          authority
        else
          addr = sock.addr
          "#{addr[3]}:#{addr[1]}"
        end
      @interceptors = interceptors
      @timeout = timeout && GrpcKit::GrpcTime.new(timeout)
    end

    def request_response(rpc, request, opts = {})
      GrpcKit.logger.debug('Calling request_respose')

      rpc.config.interceptor.interceptors = @interceptors
      do_request(rpc, request, opts)
    end

    def client_streamer(rpc, opts = {})
      GrpcKit.logger.debug('Calling client_streamer')
      rpc.config.interceptor.interceptors = @interceptors
      do_request(rpc, nil, opts)
    end

    def server_streamer(rpc, request, opts = {})
      GrpcKit.logger.debug('Calling server_streamer')
      rpc.config.interceptor.interceptors = @interceptors
      do_request(rpc, request, opts)
    end

    def bidi_streamer(rpc, requests, opts = {})
      rpc.config.interceptor.interceptors = @interceptors
      GrpcKit.logger.debug('Calling bidi_streamer')
    end

    private

    def do_request(rpc, request, **opts)
      session = GrpcKit::Session::ClientSession.new(GrpcKit::Session::IO.new(@sock))
      session.submit_settings([])

      t = GrpcKit::Transport::ClientTransport.new(session)
      cs = GrpcKit::Stream::ClientStream.new(t, rpc.config, authority: @authority, timeout: @timeout)
      rpc.invoke(cs, request, opts.merge(timeout: @timeout))
    end
  end
end
