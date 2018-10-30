# frozen_string_literal: true

require 'grpc_kit/session/io'
require 'grpc_kit/sessions/server_session'
require 'grpc_kit/rpcs/error'
require 'grpc_kit/streams/server_stream'

module GrpcKit
  class Server
    def initialize(interceptors: [])
      @sessions = []
      @rpc_descs = {}
      @error_rpc = GrpcKit::Rpcs::Server::Error.new
      @interceptors = interceptors
      @mutex = Mutex.new

      GrpcKit.logger.debug("Launched grpc_kit(v#{GrpcKit::VERSION})")
    end

    # @params handler [object]
    def handle(handler)
      handler.class.rpc_descs.each do |path, rpc_desc|
        if @rpc_descs[path]
          raise "Duplicated method registered #{path}, class: #{handler}"
        end

        @rpc_descs[path] = rpc_desc.build_server(handler, interceptors: @interceptors)
      end
    end

    def run(conn)
      establish_session(conn) do |s|
        s.submit_settings([])
        s.start
      end
    end

    def shutdown
      GrpcKit.logger.debug('Shutdown grpc_kit')

      @mutex.synchronize do
        @sessions.each(&:finish)
      end
    end

    # @params path [String]
    # @params stream [GrpcKit::Stream]
    def dispatch(path, transport)
      rpc = @rpc_descs[path]
      unless rpc
        return @error_rpc.send_bad_status(transport, session, GrpcKit::Errors::Unimplemented.new(path))
      end

      s = GrpcKit::Streams::ServerStream.new(transport: transport)
      rpc.invoke(s)
    end

    private

    def establish_session(conn)
      session = GrpcKit::Sessions::ServerSession.new(GrpcKit::Session::IO.new(conn), self)
      begin
        @mutex.synchronize { @sessions << session }
        yield(session)
      ensure
        @mutex.synchronize { @sessions.delete(session) }
      end
    end
  end
end
