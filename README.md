# GrpcKit

__UNDER DEVELOPMENT__

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

More Details in [examples directory](https://github.com/ganmacs/grpc_kit/tree/master/examples).

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
stub = Helloworld::Greeter::Stub.new('localhost', 50051)
message = stub.say_hello(Helloworld::HelloRequest.new(name: 'your name')).message
puts message
```

## Requirements

* [nghttp2](https://nghttp2.org/)

## Development

```
$ bundle install
```

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/ganmacs/grpc_kit.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

TODO
