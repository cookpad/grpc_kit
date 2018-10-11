# frozen_string_literal: true

require 'grpc_kit/rpcs/packable'
require 'grpc_kit/server_stream'

module GrpcKit
  module Rpcs
    module Client
      class RequestResponse
        include GrpcKit::Rpcs::Packable

        attr_writer :session

        def initialize(path:, protobuf:, authority:, opts: {})
          @path = path
          @protobuf = protobuf
          @authority = authority
          @opts = opts
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
          @session.start(stream_id)

          @data
        end

        def on_frame_data_recv(stream)
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
          stream.end_stream

          @data = @protobuf.decode(buf)
        end
      end
    end

    module Server
      class RequestResponse
        def initialize(handler:, method_name:, protobuf:)
          @handler = handler
          @method_name = method_name
          @protobuf = protobuf
        end

        def invoke(stream)
          ss = GrpcKit::ServerStream.new(stream: stream, protobuf: @protobuf)
          req = ss.recv
          resp = @handler.send(@method_name, req, {})
          ss.send_msg(resp)
          stream.end_write
        end
      end
    end
  end
end
