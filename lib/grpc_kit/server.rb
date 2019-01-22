# frozen_string_literal: true

require 'grpc_kit/session/io'
require 'grpc_kit/session/server_session'

module GrpcKit
  class Server
    # @param interceptors [Array<GrpcKit::Grpc::ServerInterceptor>] list of interceptors
    # @param shutdown_timeout [Integer] Number of seconds to wait for the server shutdown
    def initialize(interceptors: [], shutdown_timeout: 30)
      @interceptors = interceptors
      @shutdown_timeout = shutdown_timeout
      @sessions = []
      @rpc_descs = {}
      @mutex = Mutex.new
      @stopping = false

      GrpcKit.logger.debug("Launched grpc_kit(v#{GrpcKit::VERSION})")
    end

    # @param handler [GrpcKit::Grpc::GenericService] gRPC handler object or class
    # @return [void]
    def handle(handler)
      klass = handler.is_a?(Class) ? handler : handler.class
      unless klass.include?(GrpcKit::Grpc::GenericService)
        raise "#{klass} must include Grpc::GenericService"
      end

      klass.rpc_descs.each do |path, rpc_desc|
        if @rpc_descs[path]
          raise "Duplicated method registered #{path}, class: #{klass}"
        end

        s = handler.is_a?(Class) ? handler.new : handler
        @rpc_descs[path] = rpc_desc.build_server(s, interceptors: @interceptors)
      end
    end

    # @param conn [TCPSocket]
    # @return [void]
    def run(conn)
      raise 'Stopping server' if @stopping

      establish_session(conn) do |s|
        s.submit_settings([])
        s.start
      end
    end

    # This method is expected to be called in trap context
    # @return [void]
    def force_shutdown
      @stopping = true

      Thread.new {
        GrpcKit.logger.debug('force shutdown')
        shutdown_sessions
      }
    end

    # This method is expected to be called in trap context
    # @return [void]
    def graceful_shutdown
      @stopping = true

      Thread.new do
        GrpcKit.logger.debug('graceful shutdown')
        @mutex.synchronize { @sessions.each(&:drain) }

        end_time = Time.now + @shutdown_timeout
        loop do
          if end_time < Time.now
            GrpcKit.logger.error("Graceful shutdown is timeout (#{@shutdown_timeout}sec). Perform shutdown forceibly")
            shutdown_sessions
            break
          elsif @sessions.empty?
            break
          end
        end
      end
    end

    def session_count
      @mutex.synchronize { @sessions.size }
    end

    # @param path [String] gRPC method path
    # @param stream [GrpcKit::Streams::ServerStream]
    # @return [void]
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

    def shutdown_sessions
      @mutex.synchronize { @sessions.each(&:shutdown) }
    end

    def establish_session(conn)
      session = GrpcKit::Session::ServerSession.new(GrpcKit::Session::IO.new(conn), self)
      begin
        @mutex.synchronize { @sessions << session }
        yield(session)
      ensure
        @mutex.synchronize { @sessions.delete(session) }
      end
    end
  end
end
