# frozen_string_literal: true

require 'grpc_kit/session/io'
require 'grpc_kit/session/server_session'
require 'grpc_kit/rpc_dispatcher'

module GrpcKit
  class Server
    # @param interceptors [Array<GrpcKit::Grpc::ServerInterceptor>] list of interceptors
    # @param shutdown_timeout [Integer] Number of seconds to wait for the server shutdown
    # @param min_pool_size [Integer] A mininum thread pool size
    # @param max_pool_size [Integer] A maximum thread pool size
    def initialize(interceptors: [], shutdown_timeout: 30, min_pool_size: nil, max_pool_size: nil, settings: [])
      @interceptors = interceptors
      @shutdown_timeout = shutdown_timeout
      @min_pool_size = min_pool_size || GrpcKit::RpcDispatcher::DEFAULT_MIN
      @max_pool_size = max_pool_size || GrpcKit::RpcDispatcher::DEFAULT_MAX
      @sessions = []
      @rpc_descs = {}
      @mutex = Mutex.new
      @stopping = false
      @settings = settings

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
        s.submit_settings(@settings)
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
    # @params timeout [Boolean] timeout error could be raised or not
    # @return [void]
    def graceful_shutdown(timeout: true)
      @stopping = true

      Thread.new do
        GrpcKit.logger.debug('graceful shutdown')
        @mutex.synchronize { @sessions.each(&:drain) }

        begin
          sec = timeout ? @shutdown_timeout : 0
          Timeout.timeout(sec) do
            sleep 1 until @sessions.empty?
          end
        rescue Timeout::Error => _
          GrpcKit.logger.error("Graceful shutdown is timeout (#{@shutdown_timeout}sec). Perform shutdown forceibly")
          shutdown_sessions
        end
      end
    end

    def session_count
      @mutex.synchronize { @sessions.size }
    end

    private

    def dispatcher
      @dispatcher ||= GrpcKit::RpcDispatcher.new(@rpc_descs, min: @min_pool_size, max: @max_pool_size)
    end

    def shutdown_sessions
      @mutex.synchronize { @sessions.each(&:shutdown) }
    end

    def establish_session(conn)
      session = GrpcKit::Session::ServerSession.new(GrpcKit::Session::IO.new(conn), dispatcher)
      begin
        @mutex.synchronize { @sessions << session }
        yield(session)
      ensure
        @mutex.synchronize { @sessions.delete(session) }
      end
    end
  end
end
