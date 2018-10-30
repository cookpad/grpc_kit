# frozen_string_literal: true

require 'grpc_kit/session/io'
require 'grpc_kit/sessions/server_session'

module GrpcKit
  class Server
    def initialize(interceptors: [])
      @sessions = []
      @rpc_descs = {}
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

    def graceful_shutdown
      @mutex.synchronize do
        @sessions.each(&:drain)
      end
    end

    # @params path [String]
    # @params stream [GrpcKit::Streams::ServerStream]
    def dispatch(path, stream)
      rpc = @rpc_descs[path]
      unless rpc
        e = GrpcKit::Errors::Unimplemented.new(path)
        stream.send_status(status: e.code, msg: e.message)
        return
      end

      stream.invoke(rpc)
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
