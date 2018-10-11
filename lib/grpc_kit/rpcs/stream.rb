# frozen_string_literal: true

require 'grpc_kit/rpcs/packable'

module GrpcKit
  module Rpcs
    class Stream
      include GrpcKit::Rpcs::Packable

      def initialize(stream, handler:, method_name:, protobuf:, input: nil, output: nil, session: nil, path: nil, stream_id: nil)
        @stream = stream
        @handler = handler
        @method_name = method_name
        @protobuf = protobuf
        @sent_first_msg = false
        @input = input
        @output = output
        @session = session
        @path = path
        @stream_id = stream_id
      end

      attr_writer :stream, :output

      def stream_id
        @stream.stream_id
      end

      # client, TODO: name or position
      def send(data)
        req = @protobuf.encode(data)

        @input.write(pack(req))

        if @sent_first_msg
          stream_id = @stream.stream_id
          if @input.defered?
            @session.resume_data(stream_id)
            @input.defered = false
          end

          @session.run_once(stream_id)
        else
          stream_id = @session.submit_request(
            {
              ':method' => 'POST',
              ':scheme' => 'http',
              ':authority' => 'localhost:3000', # TODO: replace
              ':path' => @path,
              'te' => 'trailers',
              'content-type' => 'application/grpc',
              'user-agent' => "grpc-ruby/#{GrpcKit::VERSION} (grpc_kit)",
              'grpc-accept-encoding' => 'identity,deflate,gzip',
            },
            @input,
          )
          @stream_id = stream_id
          @stream = @session.run_once(stream_id)
          @sent_first_msg = true
        end
      end

      # client, TODO: name or position
      def close_and_recv
        if !@stream && @sent_first_msg
          # logging or raise
          return
        end

        @input.end_stream

        if @input.defered?
          @session.resume_data(stream_id)
          @input.defered = false
        end

        @session.start(stream_id)
        @output
      end
    end
  end
end
