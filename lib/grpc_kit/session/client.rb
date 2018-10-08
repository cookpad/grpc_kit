# frozen_string_literal: true

require 'ds9'
require 'grpc_kit/session/stream'

module GrpcKit
  module Session
    class Client < DS9::Client
      # @io [GrpcKit::IO::XXX]
      def initialize(io, handler)
        super() # initialize DS9::Session

        @io = io
        @streams = {}
        @handler = handler
      end

      def start(stream_id)
        stream = GrpcKit::Session::Stream.new(stream_id: stream_id)
        @streams[stream_id] = stream

        while want_read? || want_write?
          if stream.closed?
            break
          elsif !stream.exist_data?
            receive

            send
          else
            break
            # GrpcKit.logger.info("unknown #{stream}")
          end
        end
        # invalid if receive and send are not called
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
        @handler.on_data_chunk_recv(@streams[stream_id], data)
      end

      # provider for nghttp2_submit_response
      # def on_data_source_read(stream_id, length)
      # end

      # for nghttp2_session_callbacks_set_on_frame_send_callback
      # def on_frame_recv(frame)
      #   GrpcKit.logger.debug("on_frame_recv #{frame}")
      # end

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
        if stream
          stream.close
        end
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
