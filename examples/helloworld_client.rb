# frozen_string_literal: false

$LOAD_PATH.unshift File.expand_path('./examples/helloworld')

require 'grpc_kit'
require 'socket'
require 'pry'
require 'helloworld_services_pb'

stub = Helloworld::Greeter::Stub.new('localhost', 3000)
message = stub.say_hello(Helloworld::HelloRequest.new(msg: 'ganmacs')).msg
p message
