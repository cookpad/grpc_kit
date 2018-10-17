# frozen_string_literal: true

require 'forwardable'
require 'grpc_kit/streams/packable'

module GrpcKit
  class Stream
    include GrpcKit::Streams::Packable

    extend Forwardable

    delegate %i[stream_id end_write end_read end_write? end_read?] => :@stream

    # @params protobuf [GrpcKit::Protobuffer]
    # @params session [GrpcKit::Session::Server|GrpcKit::Session::Client]
    # @params stream [GrpcKit::Session::Stream] primitive H2 stream id
    def initialize(protobuf:, session:, stream:)
      @protobuf = protobuf
      @session = session
      @stream = stream
    end

    def each
      loop { yield(recv) }
    end

    def send(data, last: false)
      req = @protobuf.encode(data)
      @stream.write_send_data(pack(req), last: last)
    end

    def recv(last: false)
      data = unpack(read(last: last))

      unless data
        raise StopIteration
      end

      compressed, size, buf = *data

      unless size == buf.size
        raise "inconsistent data: #{buf}"
      end

      if compressed
        raise 'compress option is unsupported'
      end

      @protobuf.decode(buf)
    end

    private

    def read(last: false)
      loop do
        data = @stream.read_recv_data(last: last)
        if data.empty?
          if @stream.end_read?
            return nil
          end

          @session.run_once
          redo
        end

        return data
      end
    end
  end
end
