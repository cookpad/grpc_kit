# frozen_string_literal: true

require 'grpc_kit/status_codes'

module GrpcKit
  module Stream
    class ClientStream
      # @param transport [GrpcKit::Transport::ClientTransport]
      # @param config [GrpcKit::MethodConfig]
      # @param authority [String]
      def initialize(transport, config, authority:, timeout: nil)
        @transport = transport
        @config = config

        @authority = authority
        @timeout = timeout
        @deadline = timeout&.to_absolute_time

        @started = false
      end

      # @param data [Object]
      # @param metadata [Hash<String,String>]
      # @param last [Boolean]
      # @return [void]
      def send_msg(data, metadata: {}, last: false)
        buf =
          begin
            @config.codec.encode(data)
          rescue ArgumentError => e
            raise GrpcKit::Errors::Internal, "Error while encoding in client: #{e}"
          end

        limit_size = @config.max_send_message_size
        if limit_size && buf.bytesize > limit_size
          raise GrpcKit::Errors::ResourceExhausted, "Sending message is too large: send=#{req.bytesize}, max=#{limit_size}"
        end

        if @deadline && Time.now > @deadline
          raise GrpcKit::Errors::DeadlineExceeded, @deadline
        end

        if @started
          @transport.write_data(buf, last: last)
        else
          start_request(buf, metadata: metadata, last: last)
        end
      end

      # This method is not thread safe, never call from multiple threads at once.
      # @raise [StopIteration] when recving message finished
      # @param last [Boolean]
      # @param blocking [Boolean]
      # @return [Object]
      def recv_msg(last: false, blocking: true)
        validate_if_request_start!

        ret = do_recv(last: last, blocking: blocking)

        if @deadline && Time.now > @deadline
          raise GrpcKit::Errors::DeadlineExceeded, @deadline
        end

        ret
      end

      def close_and_send
        validate_if_request_start!

        if @deadline && Time.now > @deadline
          raise GrpcKit::Errors::DeadlineExceeded, @deadline
        end

        # send?
        @transport.close_and_flush
      end

      # @return [Object]
      def close_and_recv
        validate_if_request_start!

        @transport.close_and_flush

        ret = do_recv(last: true)

        if @deadline && Time.now > @deadline
          raise GrpcKit::Errors::DeadlineExceeded, @deadline
        end

        ret
      end

      private

      def validate_if_request_start!
        unless @started
          raise 'You should call `send_msg` method to send data'
        end
      end

      def do_recv(last: false, blocking: true)
        data =
          if blocking
            @transport.read_data(last: last)
          else
            v = @transport.read_data_nonblock(last: last)
            if v == :wait_readable
              return v
            end

            v
          end

        if data.nil?
          check_status!
          raise StopIteration
        elsif last
          check_status!
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

        raise StopIteration if buf.nil?

        begin
          @config.codec.decode(buf)
        rescue ArgumentError, TypeError => e
          raise GrpcKit::Errors::Internal, "Error while decoding in Client: #{e}"
        end
      end

      def check_status!
        if status.code != GrpcKit::StatusCodes::OK
          raise GrpcKit::Errors.from_status_code(status.code, status.msg)
        else
          GrpcKit.logger.debug('request is success')
        end
      end

      Status = Struct.new(:code, :msg, :metadata)

      def status
        @status ||=
          begin
            headers = @transport.recv_headers
            Status.new(headers.grpc_status, headers.status_message, headers.metadata)
          end
      end

      def start_request(buf = nil, last: nil, metadata: {}, timeout: @timeout, authority: @authority)
        hdrs = {
          ':method' => 'POST',
          ':scheme' => 'http',
          ':path' => @config.path,
          ':authority' => authority,
          'grpc-timeout' => timeout&.to_s,
          'te' => 'trailers',
          'content-type' => 'application/grpc',
          'user-agent' => "grpc-ruby/#{GrpcKit::VERSION} (grpc_kit)",
          'grpc-accept-encoding' => 'identity,deflate,gzip',
        }

        metadata.each do |k, v|
          if k.start_with?('grpc-')
            # https://github.com/grpc/grpc/blob/ffac9d90b18cb076b1c952faa55ce4e049cbc9a6/doc/PROTOCOL-HTTP2.md
            GrpcKit.logger.info("metadata name wich starts with 'grpc-' is reserved for future GRPC metadata")
          else
            hdrs[k] = v
          end
        end

        @transport.start_request(buf, hdrs.compact, last: last)
        @started = true
      end
    end
  end
end
