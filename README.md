# GrpcKit

[![Build Status](https://travis-ci.org/cookpad/grpc_kit.svg?branch=master)](https://travis-ci.org/cookpad/grpc_kit)
[![Gem Version](https://badge.fury.io/rb/grpc_kit.svg)](https://badge.fury.io/rb/grpc_kit)

A kit for creating [gRPC](https://grpc.io/) server/client in Ruby.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'grpc_kit'
```

And then execute:

```
$ bundle
```

Or install it yourself as:

```
$ gem install grpc_kit
```

## Usage

More Details in [examples directory](https://github.com/cookpad/grpc_kit/tree/master/examples).

##### Server

```ruby
sock = TCPServer.new(50051)
server = GrpcKit::Server.new
server.handle(GreeterServer.new)

loop do
  conn = sock.accept
  server.run(conn)
end
```

##### Client

```ruby
sock = TCPSocket.new('localhost', 50051)
stub = Helloworld::Greeter::Stub.new(sock)
message = stub.say_hello(Helloworld::HelloRequest.new(name: 'your name')).message
puts message
```

## Development

```
$ bundle install
```

## Projects using grpc_kit

* [griffin](https://github.com/cookpad/griffin) Multi process gRPC server in Ruby

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/cookpad/grpc_kit.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

