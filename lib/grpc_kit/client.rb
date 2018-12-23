# frozen_string_literal: true

require 'grpc_kit/grpc_time'
require 'grpc_kit/session/io'
require 'grpc_kit/session/client_session'
require 'grpc_kit/stream/client_stream'
require 'grpc_kit/transport/client_transport'

module GrpcKit
  class Client
    # @param sock [TCPSocket]
    # @param authority [nil, String]
    # @param interceptors [Array<GrpcKit::Grpc::ClientInterceptor>] list of interceptors
    # @param timeout [nil, Integer, String]
    def initialize(sock, authority: nil, interceptors: [], timeout: nil)
      @sock = sock
      @authority =
        if authority
          authority
        else
          addr = sock.addr
          "#{addr[3]}:#{addr[1]}"
        end

      @timeout = timeout && GrpcKit::GrpcTime.new(timeout)

      build_rpcs(interceptors)
    end

    # @param rpc [GrpcKit::Rpcs::Client::RequestResponse]
    # @param request [Object]
    # @param opts [Hash]
    def request_response(rpc, request, opts = {})
      GrpcKit.logger.debug('Calling request_respose')
      do_request(rpc, request, opts)
    end

    # @param rpc [GrpcKit::Rpcs::Client::ClientStreamer]
    # @param opts [Hash]
    def client_streamer(rpc, opts = {})
      GrpcKit.logger.debug('Calling client_streamer')
      do_request(rpc, nil, opts)
    end

    # @param rpc [GrpcKit::Rpcs::Client::ServerStreamer]
    # @param request [Object]
    # @param opts [Hash]
    def server_streamer(rpc, request, opts = {})
      GrpcKit.logger.debug('Calling server_streamer')
      do_request(rpc, request, opts)
    end

    # @param rpc [GrpcKit::Rpcs::Client::ServerStreamer]
    # @param _requests [Object] it's for compatibility, no use
    # @param opts [Hash]
    def bidi_streamer(rpc, _requests, opts = {})
      GrpcKit.logger.debug('Calling bidi_streamer')
      do_request(rpc, nil, opts)
    end

    private

    def do_request(rpc, request, **opts)
      t = GrpcKit::Transport::ClientTransport.new(session)
      timeout = (opts[:timeout] && GrpcKit::GrpcTime.new(opts[:timeout])) || @timeout

      cs = GrpcKit::Stream::ClientStream.new(t, rpc.config, authority: @authority, timeout: timeout)
      rpc.invoke(cs, request, timeout: timeout, **opts)
    end

    def session
      @session ||=
        begin
          s = GrpcKit::Session::ClientSession.new(GrpcKit::Session::IO.new(@sock))
          s.submit_settings([])
          s
        end
    end
  end
end
