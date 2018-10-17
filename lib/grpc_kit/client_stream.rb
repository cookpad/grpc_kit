# frozen_string_literal: true

require 'grpc_kit/rpcs/packable'

module GrpcKit
  class ClientStream
    include GrpcKit::Rpcs::Packable

    def initialize(path:, protobuf:, session:)
      @path = path
      @session = session
      @protobuf = protobuf
      @stream = nil
    end

    def each
      loop { yield(recv) }
    end

    def send(data, metadata: {}, timeout: nil, last: false)
      if @stream
        unless @stream.end_write?
          @session.resume_data(@stream.stream_id)
        end
      else
        @stream = @session.start_request(SendBuffer.new, metadata: metadata, timeout: timeout, path: @path)
      end

      req = @protobuf.encode(data)
      @stream.write_send_data(pack(req), last: last)

      @session.run_once
    end

    def recv(last: false)
      unless @stream
        raise 'You should call `send` method to send data'
      end

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

    def close_and_recv
      unless @stream
        raise 'You should call `send` method to send data'
      end

      unless @stream.end_write?
        @session.resume_data(@stream.stream_id)
      end

      @stream.end_write
      @session.start(@stream.stream_id)
      @stream.end_read

      data = []
      each { |d| data.push(d) }
      data
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

    class SendBuffer
      def initialize
        @buffer = nil
        @pos = 0
        @end_write = false
      end

      def write(data, last: false)
        end_write if last

        if @buffer
          @buffer << data
        else
          @buffer = data
        end

        data.size
      end

      def end_write
        @end_write = true
      end

      def end_write?
        @end_write
      end

      def read(size)
        if @buffer.nil?
          return false
        end

        data = @buffer.slice!(0, size)
        if !data.empty?
          data
        elsif end_write?
          nil # EOF
        else
          false # deferred
        end
      end
    end
  end
end
