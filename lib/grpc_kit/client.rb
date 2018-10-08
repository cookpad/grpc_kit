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
      sock = TCPSocket.new(@host, @port)

      cli = rpc_desc.build_client(opts.delete(:authority) || @authority, opts)
      session = GrpcKit::Session::Client.new(@io.new(sock, sock), cli)
      cli.session = session

      session.submit_settings([])
      cli.invoke(request)
    end

    def client_streamer(rpc_desc, requests, opts = {})
      GrpcKit.logger.info('Calling client_streamer')
    end

    def server_streamer(rpc_desc, request, opts = {})
      GrpcKit.logger.info('Calling server_streamer')

      sock = TCPSocket.new(@host, @port)

      cli = rpc_desc.build_client(opts.delete(:authority) || @authority, opts)
      session = GrpcKit::Session::Client.new(@io.new(sock, sock), cli)
      cli.session = session

      session.submit_settings([])
      cli.invoke(request)
    end

    def bidi_streamer(rpc_desc, requests, opts = {})
      GrpcKit.logger.info('Calling bidi_streamer')
    end
  end
end
