# frozen_string_literal: true

require 'grpc_kit/io/basic'
require 'grpc_kit/session/server'

module GrpcKit
  class Server
    def initialize
      @sessions = []
      @handler = {}
      @rpc_descs = {}
    end

    # @params handler [object]
    def handle(handler)
      klass = handler.class

      klass.rpc_descs.values.each do |rpc_desc|
        path = rpc_desc.path(klass.service_name)
        if @rpc_descs[path]
          raise "Duplicated method registered #{key}, class: #{handler}"
        end

        @rpc_descs[path] = [rpc_desc, handler]
      end
    end

    def run
      GrpcKit.logger.info("Start grpc_kit v#{GrpcKit::VERSION}")
      # XXX
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

    def on_data_chunk_recv(stream, data)
      compressed, length, buf = data.unpack('CNa*')
      if compressed == 0      # TODO: not
        if length != buf.size
          raise 'recived data inconsistent'
        end

        stream.recv(buf)
      else
        raise 'not supported'
      end
    end

    def on_frame_data_recv(stream)
      return unless stream.exist_data?

      path = stream.headers[':path']
      rpc = @rpc_descs[path.to_sym]
      if rpc
        resp = rpc[0].invoke(rpc[1], stream.data)
        buf = [0, resp.length, resp].pack('CNa*')
        stream.data = ''
        stream.send(StringIO.new(buf))
      else
        # TODO: 404
        raise "unkown path #{path}"
      end
    end
  end
end
