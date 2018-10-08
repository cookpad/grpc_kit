require 'socket'
require 'grpc_kit/session/client'

module GrpcKit
  class Client
    def initialize(host, port, io = GrpcKit::IO::Basic)
      @host = host
      @port = port
      @authority = "#{host}:#{port}"
      @io = io
    end

    # @params handler [object]
    def handle(handler)
      klass = handler.class

      klass.rpc_descs.values.each do |rpc_desc|
        path = rpc_desc.path(klass.service_name)
        if @rpc_descs[path]
          raise "Duplicated method registered #{key}, class: #{handler}"
        end

        @rpc_descs[path] = [rpc_desc, handler]
      end
    end

    class RequestResponse
      attr_writer :session

      def initialize(path, opts = {})
        @path = path
        @opts = opts
        @session = nil
        @data = ''
      end

      def invoke(data)
        @session.submit_settings([])

        stream_id = submit_request(data)
        @session.start(stream_id)
        @data
      end

      def on_data_chunk_recv(stream, data)
        compressed, length, buf = data.unpack('CNa*')
        if compressed == 0 # TODO: not
          if length != buf.size
            raise 'recived data inconsistent'
          end

          @data << buf
          stream.recv2(buf)
        else
          raise 'not supported'
        end
      end

      private

      def submit_request(data)
        @session.submit_request(
          {
            ':method' => 'POST',
            ':scheme' => 'http',
            ':authority' => @opts[:authority],
            ':path' => @path.to_s,
            'te' => 'trailers',
            'content-type' => 'application/grpc',
            'user-agent' => "grpc-ruby/#{GrpcKit::VERSION} (grpc_kit)",
            'grpc-accept-encoding' => 'identity,deflate,gzip',
          },
          data,
        )
      end
    end

    def request_response(path, request, rpc_desc, opts = {})
      GrpcKit.logger.info('Calling request_respose')
      sock = TCPSocket.new(@host, @port)

      rr = RequestResponse.new(path, { authority: @authority }.merge(opts))
      session = GrpcKit::Session::Client.new(@io.new(sock, sock), rr)
      rr.session = session

      req = rpc_desc.encode2(request)
      data = [0, req.length, req].pack('CNa*')

      resp = rr.invoke(data)
      rpc_desc.decode2(resp)
    end

    def client_streamer(path, requests, rpc, opts = {})
      GrpcKit.logger.info('Calling client_streamer')
    end

    def server_streamer(path, request, metadata, opts = {})
      GrpcKit.logger.info('Calling server_streamer')
    end

    def bidi_streamer(path, requests, metadata, opts = {})
      GrpcKit.logger.info('Calling bidi_streamer')
    end
  end
end
