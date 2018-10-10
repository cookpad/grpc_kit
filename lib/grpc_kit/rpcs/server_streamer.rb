# frozen_string_literal: true

require 'grpc_kit/rpcs/packable'
require 'grpc_kit/rpcs/stream'

module GrpcKit
  module Rpcs
    module Client
      class ServerStreamer
        include GrpcKit::Rpcs::Packable

        attr_writer :session

        def initialize(path:, protobuf:, authority:, opts: {})
          @path = path
          @protobuf = protobuf
          @authority = authority
          @opts = opts
          @data = []
        end

        def invoke(data)
          req = @protobuf.encode(data)

          stream_id = @session.submit_request(
            {
              ':method' => 'POST',
              ':scheme' => 'http',
              ':authority' => @authority,
              ':path' => @path,
              'te' => 'trailers',
              'content-type' => 'application/grpc',
              'user-agent' => "grpc-ruby/#{GrpcKit::VERSION} (grpc_kit)",
              'grpc-accept-encoding' => 'identity,deflate,gzip',
            },
            pack(req),
          )
          s = @session.run_once(stream_id)

          @stream = GrpcKit::Rpcs::Stream.new(
            s,
            handler: @handler,
            method_name: @method_name,
            protobuf: @protobuf,
            session: @session,
            output: [],
            stream_id: stream_id,
          )
        end

        def on_frame_data_recv(stream)
          # nothing
        end
      end
    end

    module Server
      class ServerStreamer
        include GrpcKit::Rpcs::Packable

        def initialize(handler:, method_name:, protobuf:)
          @handler = handler
          @method_name = method_name
          @protobuf = protobuf
        end

        def invoke(stream)
          bufs = +''
          while (data = stream.consume_read_data)
            compressed, size, buf = unpack(data)

            unless size == buf.size
              raise "inconsistent data: #{buf}"
            end

            if compressed
              raise 'compress option is unsupported'
            end

            bufs << buf
          end
          stream.end_read

          req = @protobuf.decode(bufs)
          s = GrpcKit::Rpcs::Stream.new(
            stream,
            handler: @handler,
            method_name: @method_name,
            protobuf: @protobuf,
          )
          @handler.send(@method_name, req, s)
          stream.end_write
        end
      end
    end
  end
end
