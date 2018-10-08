# frozen_string_literal: true

require 'grpc_kit/io/basic'
require 'grpc_kit/session/server'

module GrpcKit
  class Server
    def initialize
      @sessions = []
      @rpc_descs = {}
    end

    # @params handler [object]
    def handle(handler)
      handler.class.rpc_descs.each do |path, rpc_desc|
        if @rpc_descs[path]
          raise "Duplicated method registered #{path}, class: #{handler}"
        end

        @rpc_descs[path] = rpc_desc.build_server(handler)
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

    def session_start(conn, io = GrpcKit::IO::Basic)
      session = GrpcKit::Session::Server.new(io.new(conn, conn), self) # TODO: change self to proper object
      @sessions << session

      session.submit_settings([])
      session.start # blocking
    end

    # TODO: name
    def on_frame_data_recv(stream)
      path = stream.headers[':path']
      rpc = @rpc_descs[path.to_sym]
      unless rpc
        raise "Unkown path #{path}"
      end

      rpc.invoke(stream)
    end
  end
end
