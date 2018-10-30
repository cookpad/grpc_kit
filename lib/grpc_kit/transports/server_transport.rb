# frozen_string_literal: true

require 'forwardable'
require 'grpc_kit/streams/packable'

module GrpcKit
  module Transports
    class ServerTransport
      include GrpcKit::Streams::Packable

      extend Forwardable

      delegate %i[stream_id end_write end_read end_write? end_read? close_remote? headers] => :@stream

      # @params session [GrpcKit::Session::Server|GrpcKit::Session::Client]
      # @params stream [GrpcKit::Session::Stream] primitive H2 stream id
      def initialize(session:, stream:, config: nil)
        @session = session
        @stream = stream
        @config = config
      end

      def each
        loop do
          data = recv
          return if data.nil?

          yield(data)
        end
      end

      def write_data(buf, last: false, limit_size: nil)
        if limit_size && buf.bytesize > limit_size
          raise GrpcKit::Errors::ResourceExhausted, "Sending message is too large: send=#{req.bytesize}, max=#{limit_size}"
        end

        @stream.write_send_data(pack(buf), last: last)
      end

      def read_data(last: false, limit_size: nil)
        data = unpack(read(last: last))

        return nil unless data

        compressed, size, buf = *data

        unless size == buf.size
          raise "inconsistent data: #{buf}"
        end

        if limit_size && size > limit_size
          raise GrpcKit::Errors::ResourceExhausted, "Receving message is too large: recevied=#{size}, max=#{limit_size}"
        end

        if compressed
          raise 'compress option is unsupported'
        end

        buf
      end

      def send_trailer(status: GrpcKit::StatusCodes::OK, msg: nil, metadata: {})
        trailer = metadata.dup
        trailer['grpc-status'] = status.to_s
        if msg
          trailer['grpc-message'] = msg
        end

        @stream.write_trailers_data(trailer)
        @stream.end_write
      end

      # TODO: use actual data
      def submit_response(_header = nil, piggyback_trailer: false)
        headers = { ':status' => '200', 'content-type' => 'application/grpc' }

        # ds9 does not support nthttp2_submit_{response|request} without body
        # if piggyback_trailer
        #   headers.merge!(@stream.trailer_data)
        #   @stream.need_trailer = false
        # else
        headers['accept-encoding'] = 'identity'
        # end

        @session.submit_response(@stream.stream_id, headers)
      end

      private

      def read(last: false)
        loop do
          data = @stream.read_recv_data(last: last)
          return data unless data.empty?

          if @stream.close_remote?
            # it do not receive data which we need, it may receive invalid grpc-status
            unless @stream.end_read?
              return nil
            end

            return nil
          end

          @session.run_once
        end
      end
    end
  end
end
