# frozen_string_literal: false

require 'socket'
require 'grpc_kit/session/client'
require 'grpc_kit/rpcs'

module GrpcKit
  class Client
    def initialize(host, port, io = GrpcKit::IO::Basic)
      @host = host
      @port = port
      @authority = "#{host}:#{port}"
      @io = io
    end

    def request_response(rpc_desc, request, opts = {})
      GrpcKit.logger.info('Calling request_respose')
      do_request(rpc_desc, request, opts)
    end

    def client_streamer(rpc_desc, opts = {})
      GrpcKit.logger.info('Calling client_streamer')
      do_request(rpc_desc, nil, opts)
    end

    def server_streamer(rpc_desc, request, opts = {})
      GrpcKit.logger.info('Calling server_streamer')
      do_request(rpc_desc, request, opts)
    end

    def bidi_streamer(rpc_desc, requests, opts = {})
      GrpcKit.logger.info('Calling bidi_streamer')
    end

    private

    def do_request(rpc_desc, request, opts)
      sock = TCPSocket.new(@host, @port) # XXX

      cli = rpc_desc.build_client(opts)
      session = GrpcKit::Session::Client.new(
        @io.new(sock, sock),
        cli,
        authority: opts.delete(:authority) || @authority,
      )

      session.submit_settings([])
      rpc.invoke(session, request, opts)
    end
  end
end
