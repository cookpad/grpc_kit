# frozen_string_literal: true

$LOAD_PATH.unshift File.expand_path('./examples/helloworld')

require 'grpc_kit'
require 'socket'
require 'pry'
require 'helloworld_services_pb'

class GreeterServer < Helloworld::Greeter::Service
  def say_hello(hello_req, _unused_call)
    Helloworld::HelloReply.new(msg: "Hello #{hello_req.msg}")
  end
end

sock = TCPServer.new(3000)

server = GrpcKit::Server.new
server.handle(GreeterServer.new)
server.run

loop do
  conn = sock.accept
  server.session_start(conn)
end
