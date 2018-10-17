# frozen_string_literal: true

require 'grpc_kit/session/io'
require 'grpc_kit/session/server'

module GrpcKit
  class Server
    def initialize(interceptors: [])
      @sessions = []
      @rpc_descs = {}
      @interceptors = interceptors
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

    def run
      GrpcKit.logger.info("Start grpc_kit v#{GrpcKit::VERSION}")

      @rpc_descs.freeze
    end

    def stop
      GrpcKit.logger.info('Stop grpc_kit')
      @sessions.each(&:stop)
    end

    def session_start(conn)
      session = GrpcKit::Session::Server.new(
        GrpcKit::Session::IO.new(conn),
        self,
      )
      @sessions << session

      session.submit_settings([])
      session.start # blocking
      session.finish
    end

    def dispatch(stream, session)
      rpc = @rpc_descs[stream.headers.path]
      unless rpc
        raise "Unkown path #{path}"
      end

      rpc.invoke(stream, session)
    end
  end
end
