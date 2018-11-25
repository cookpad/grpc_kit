# frozen_string_literal: true

$LOAD_PATH.unshift File.expand_path('./examples/helloworld')

require 'grpc_kit'
require 'socket'
require 'pry'
require 'helloworld_services_pb'

HOST = 'localhost'
PORT = 50051

sock = TCPSocket.new(HOST, PORT)
stub = Helloworld::Greeter::Stub.new(sock)
message = stub.say_hello(Helloworld::HelloRequest.new(name: 'ganmacs')).message
p message
