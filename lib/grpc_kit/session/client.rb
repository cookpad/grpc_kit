# frozen_string_literal: true

require 'ds9'

module GrpcKit
  module Session
    class Client < DS9::Server
      # def initialize
      # end

      # private

      # # provider for nghttp2_submit_response
      # def on_data_source_read(stream_id, length)
      # end

      # # for nghttp2_session_callbacks_set_send_callback
      # def send_event(string)
      # end

      # # for nghttp2_session_callbacks_set_recv_callback
      # def recv_event(length)
      # end

      # # for nghttp2_session_callbacks_set_on_frame_send_callback
      # def on_frame_recv(frame)
      #   true
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

      # # for nghttp2_session_callbacks_set_on_stream_close_callback
      # def on_stream_close(id, error_code)
      # end

      # # for nghttp2_session_callbacks_set_on_data_chunk_recv_callback
      # def on_data_chunk_recv(id, data, flags)
      # end

      # # nghttp2_session_callbacks_set_before_frame_send_callback
      # def before_frame_send(frame)
      # end
    end
  end
end
