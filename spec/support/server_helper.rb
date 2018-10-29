# frozen_string_literal: false

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
end
