# frozen_string_literal: true

require 'grpc_kit/session/io'
require 'grpc_kit/session/server'

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

    def dispatch(stream, session)
      rpc = @rpc_descs[stream.headers.path]
      unless rpc
        return @error_rpc.send_bad_status(stream, session, GrpcKit::Errors::Unimplemented.new(stream.headers.path))
      end

      rpc.invoke(stream, session)
    end

    private

    def establish_session(conn)
      session = GrpcKit::Session::Server.new(GrpcKit::Session::IO.new(conn), self)
      begin
        @mutex.synchronize { @sessions << session }
        yield(session)
      ensure
        @mutex.synchronize { @sessions.delete(session) }
      end
    end
  end
end
