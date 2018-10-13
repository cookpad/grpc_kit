# frozen_string_literal: true

require 'ds9'
require 'grpc_kit/session/stream'

module GrpcKit
  module Session
    class Client < DS9::Client
      # @io [GrpcKit::IO::XXX]
      def initialize(io, handler, opts = {})
        super() # initialize DS9::Session

        @io = io
        @streams = {}
        @handler = handler
        @request = {
          ':method' => 'POST',
          ':scheme' => 'http',
          ':authority' => opts[:authority],
          'te' => 'trailers',
          'content-type' => 'application/grpc',
          'user-agent' => "grpc-ruby/#{GrpcKit::VERSION} (grpc_kit)",
          'grpc-accept-encoding' => 'identity,deflate,gzip',
        }
      end

      def submit_request(body, path:, metadata: {}, timeout: nil, **headers)
        val = headers.merge(':path' => path)
        if timeout
          val['grpc-timeout'] = timeout
        end

        super(metadata.merge(@request.merge(val)), body)
      end

      def start(stream_id)
        stream = @streams[stream_id]
        unless stream
          stream = GrpcKit::Session::Stream.new(stream_id: stream_id, session: self)
          @streams[stream_id] = stream
        end

        while !stream.end_stream? && (want_read? || want_write?)
          if want_read?
            receive
          end

          if want_write?
            send
          end
        end

        # invalid if receive and send are not called
      end

      def run_once(stream_id, end_write: false)
        stream = @streams[stream_id]
        unless stream
          stream = GrpcKit::Session::Stream.new(stream_id: stream_id, session: self)
          @streams[stream_id] = stream
        end

        if end_write
          @streams[stream_id].end_write # XXX
        end

        if !stream.end_stream? && (want_read? || want_write?)
          if want_read?
            receive
          end

          if want_write?
            send
          end
        end

        stream
      end

      private

      # for nghttp2_session_callbacks_set_send_callback
      # override
      def send_event(string)
        @io.write(string)
      end

      # for nghttp2_session_callbacks_set_recv_callback
      # override
      def recv_event(length)
        @io.read(length)
      end

      # for nghttp2_session_callbacks_set_on_data_chunk_recv_callback
      def on_data_chunk_recv(stream_id, data, flags)
        @streams[stream_id].recv(data)
        # @handler.on_data_chunk_recv(@streams[stream_id], data)
      end

      # provider for nghttp2_submit_response
      # def on_data_source_read(stream_id, length)
      # end

      # for nghttp2_session_callbacks_set_on_frame_send_callback
      def on_frame_recv(frame)
        GrpcKit.logger.debug("on_frame_recv #{frame}")
        case frame
        when DS9::Frames::Data
          stream = @streams[frame.stream_id]

          if frame.end_stream?
            stream.end_read
          end

          unless stream.handling
            stream.handling = true
          end

        # when DS9::Frames::Headers
        # when DS9::Frames::Goaway
        # when DS9::Frames::RstStream
        # else
          # GrpcKit.logger.info("unsupport frame #{frame}")
        end

        true
      end

      # # for nghttp2_session_callbacks_set_on_frame_not_send_callback
      # def on_frame_not_send(frame, reason)
      # end

      # # for nghttp2_session_callbacks_set_on_frame_send_callback
      # def on_frame_send(frame, reason)
      # end

      # # for nghttp2_session_callbacks_set_on_header_callback
      # def on_header(name, value, frame, flags)
      # end

      # # for nghttp2_session_callbacks_set_on_begin_headers_callback
      # def on_begin_header(name, value, frame, flags)
      # end

      # # for nghttp2_session_callbacks_set_on_begin_frame_callback
      # def on_begin_frame(frame_header)
      # end

      # # for nghttp2_session_callbacks_set_on_invalid_frame_recv_callback
      # def on_invalid_frame_recv(frame, error_code)
      # end

      # for nghttp2_session_callbacks_set_on_stream_close_callback
      def on_stream_close(stream_id, error_code)
        GrpcKit.logger.debug("on_stream_close stream_id=#{stream_id}, error_code=#{error_code}")
        stream = @streams.delete(stream_id)
        return unless stream

        stream.end_stream
      end

      # # for nghttp2_session_callbacks_set_on_data_chunk_recv_callback
      # def on_data_chunk_recv(id, data, flags)
      # end

      # # nghttp2_session_callbacks_set_before_frame_send_callback
      # def before_frame_send(frame)
      # end
    end
  end
end
