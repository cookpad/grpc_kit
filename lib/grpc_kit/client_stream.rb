# frozen_string_literal: true

require 'grpc_kit/rpcs/packable'

module GrpcKit
  class ClientStream
    include GrpcKit::Rpcs::Packable

    def initialize(path:, protobuf:, session:)
      @path = path
      @session = session
      @protobuf = protobuf
      @sent_first_msg = false
      @input = Sock.new
      @stream = nil
    end

    def send(data, end_stream: false)
      req = @protobuf.encode(data)
      @input.write(pack(req))

      if @sent_first_msg
        stream_id = @stream.stream_id

        unless @input.end_write?
          @session.resume_data(stream_id)
        end

        @session.run_once(stream_id)
      else
        stream_id = @session.submit_request(@input, path: @path)
        @stream = @session.run_once(stream_id, end_write: end_stream)
        @sent_first_msg = true
      end
    end

    def recv
      req = nil

      loop do
        data = @stream.consume_read_data

        if data.nil?
          if @stream.end_read?
            break
          else
            next
          end
        end

        compressed, size, buf = unpack(data)

        unless size == buf.size
          raise "inconsistent data: #{buf}"
        end

        if compressed
          raise 'compress option is unsupported'
        end

        req = @protobuf.decode(buf)
        if req
          return req
        end
      end

      raise StopIteration
    end

    def close_and_recv
      if !@stream && @sent_first_msg
        raise '`send` must be call at least once'
      end

      unless @input.end_write?
        @session.resume_data(@stream.stream_id)
      end
      @input.end_write
      @stream.end_write
      @session.start(@stream.stream_id)

      data = []
      loop { data.push(recv) }
      data
    end

    class Sock
      def initialize
        @data = StringIO.new(+'')
        @pos = 0
        @end_write = false
      end

      def write(data)
        now = @data.pos
        @data.pos = @pos # move write pos
        v = @data.write(data)
        @pos += v
        @data.pos = now
        v
      end

      def end_write
        @end_write = true
      end

      def end_write?
        @end_write
      end

      def read(size)
        data = @data.read(size)
        if data
          data
        elsif @end_write
          nil # EOF
        else
          false # deferred
        end
      end
    end
  end
end
