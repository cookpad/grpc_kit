# frozen_string_literal: true

require 'grpc_kit/session/io'
require 'grpc_kit/session/server_session'

module GrpcKit
  class Server
    def initialize(interceptors: [])
      @sessions = []
      @rpc_descs = {}
      @interceptors = interceptors
      @mutex = Mutex.new
      @stopping = false
      @max_graceful_wait = 60

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
      raise 'Stopping server' if @stopping

      establish_session(conn) do |s|
        s.submit_settings([])
        s.start
      end
    end

    def wait_shutdown
      loop do
        return if @stopping

        sleep 1
      end
    end

    def force_shutdown
      # expected to be called in trap context
      Thread.new do
        @mutex.synchronize do
          GrpcKit.logger.debug('force shutdown')
          @stopping = true
          @sessions.each(&:shutdown)
        end
      end
    end

    def graceful_shutdown
      # expected to be called in trap context
      Thread.new do
        GrpcKit.logger.debug('graceful shutdown')
        @mutex.synchronize { @sessions.each(&:drain) }
        begin
          Timeout.timeout(@max_graceful_wait) do
            loop do
              break if @mutex.synchronize { @sessions.empty? }

              sleep 1
            end
          end
        rescue Timeout::Error => _
          GrpcKit.logger.debug('Max wait time expired')
        end

        @stopping = true
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
