# frozen_string_literal: false

$LOAD_PATH.unshift File.expand_path('./examples/helloworld')

require 'grpc_kit'
require 'socket'
require 'pry'
require 'helloworld_services_pb'

stub = Helloworld::Greeter::Stub.new('localhost', 50051)
message = stub.say_hello(Helloworld::HelloRequest.new(name: 'ganmacs')).message
p message
