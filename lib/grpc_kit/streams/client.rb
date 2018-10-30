# frozen_string_literal: true

require 'grpc_kit/streams/send_buffer'
require 'grpc_kit/status_codes'

module GrpcKit
  module Streams
    class Client
      # @params transport [GrpcKit::Transports::ClientTransport]
      # @params config [GrpcKit::MethodConfig]
      # @params authority [String]
      def initialize(transport:, config:, authority:)
        @config = config
        @authority = authority
        @transport = transport
        @sent_first_msg = false
      end

      def send_msg(data, metadata: {}, timeout: nil, last: false)
        if @sent_first_msg
          # unless metadata.empty?
          #   raise 'You can attach metadata at first send_msg' # XXX
          # end

          @transport.resume_if_need
        else
          headers = build_headers(metadata: metadata, timeout: timeout)
          @transport.send_request(GrpcKit::Streams::SendBuffer.new, headers)
          @sent_first_msg = true
        end

        buf =
          begin
            @config.protobuf.encode(data)
          rescue ArgumentError => e
            raise GrpcKit::Errors::Internal, "Error while encoding in client: #{e}"
          end

        limit_size = @config.max_send_message_size
        if limit_size && buf.bytesize > limit_size
          raise GrpcKit::Errors::ResourceExhausted, "Sending message is too large: send=#{req.bytesize}, max=#{limit_size}"
        end

        @transport.write_data(buf, last: last)
        @transport.run_once
      end

      def each
        validate_if_request_start!

        loop { yield(do_recv) }
      end

      def recv_msg(last: false)
        validate_if_request_start!

        do_recv(last: last)
      end

      def close_and_recv
        validate_if_request_start!

        @transport.resume_if_need
        @transport.start

        check_status!

        data = []
        loop { data.push(do_recv) }
        data
      end

      private

      def validate_if_request_start!
        unless @sent_first_msg
          raise 'You should call `send_msg` method to send data'
        end
      end

      def do_recv(last: false)
        data = @transport.read_data(last: last)

        if data.nil?
          check_status!
          raise StopIteration
        end

        compressed, size, buf = *data

        unless size == buf.size
          raise "inconsistent data: #{buf}"
        end

        limit_size = @config.max_receive_message_size
        if limit_size && size > limit_size
          raise GrpcKit::Errors::ResourceExhausted, "Receving message is too large: recevied=#{size}, max=#{limit_size}"
        end

        if compressed
          raise 'compress option is unsupported'
        end

        begin
          @config.protobuf.decode(buf)
        rescue ArgumentError => e
          raise GrpcKit::Errors::Internal, "Error while decoding in Client: #{e}"
        end
      end

      def check_status!
        @transport.wait_close
        headers = @transport.recv_headers

        if headers.grpc_status != GrpcKit::StatusCodes::OK
          raise GrpcKit::Errors.from_status_code(headers.grpc_status, headers.status_message)
        else
          GrpcKit.logger.debug('request is success')
        end
      end

      def build_headers(metadata: {}, timeout: nil, **headers)
        # TODO: an order of Headers is important?
        hdrs = {
          ':method' => 'POST',
          ':scheme' => 'http',
          ':path' => @config.path,
          ':authority' => @authority,
          'grpc-timeout' => timeout,
          'te' => 'trailers',
          'content-type' => 'application/grpc',
          'user-agent' => "grpc-ruby/#{GrpcKit::VERSION} (grpc_kit)",
          'grpc-accept-encoding' => 'identity,deflate,gzip',
        }.merge(headers)

        metadata.each do |k, v|
          if k.start_with?('grpc-')
            # https://github.com/grpc/grpc/blob/ffac9d90b18cb076b1c952faa55ce4e049cbc9a6/doc/PROTOCOL-HTTP2.md
            GrpcKit.logger.info("metadata name wich starts with 'grpc-' is reserved for future GRPC")
          else
            hdrs[k] = v
          end
        end

        hdrs.compact
      end
    end
  end
end
