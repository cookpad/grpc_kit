# frozen_string_literal: true

require 'socket'

class ServerHelper
  def self.build_server(port = 50051, service, interceptors: [])
    s =
      if interceptors.empty?
        GrpcKit::Server.new
      else
        GrpcKit::Server.new(interceptors: interceptors)
      end
    s.handle(service)
    sock = TCPServer.new(port)

    Thread.new do
      s.run(sock.accept)
    end
    sock
  end

  def self.connect(host = 'localhost', port = 50051)
    TCPSocket.new(host, port)
  end
end
