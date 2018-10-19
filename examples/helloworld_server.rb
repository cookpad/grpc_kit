# frozen_string_literal: true

$LOAD_PATH.unshift File.expand_path('./examples/helloworld')

require 'grpc_kit'
require 'socket'
require 'pry'
require 'helloworld_services_pb'

class GreeterServer < Helloworld::Greeter::Service
  def say_hello(hello_req, _unused_call)
    Helloworld::HelloReply.new(message: "Hello #{hello_req.name}")
  end
end

sock = TCPServer.new(50051)

server = GrpcKit::Server.new
server.handle(GreeterServer.new)

loop do
  conn = sock.accept
  server.run(conn)
end
