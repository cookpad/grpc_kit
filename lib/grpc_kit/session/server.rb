# frozen_string_literal: true

require 'forwardable'
require 'ds9'
require 'grpc_kit/session/stream'
require 'grpc_kit/transports/server_transport'

module GrpcKit
  module Session
    class Server < DS9::Server
      extend Forwardable

      delegate %i[send_event recv_event] => :@io

      # @params io [GrpcKit::Session::IO]
      # @params dispatcher [GrpcKit::Server]
      def initialize(io, dispatcher)
        super() # initialize DS9::Session

        @io = io
        @streams = {}
        @stop = false
        @dispatcher = dispatcher
        @peer_shutdowned = false
        @inflights = []
      end

      def start
        @io.wait_readable
        loop do
          invoke

          if !want_read? && !want_write?
            break
          elsif @peer_shutdowned && !want_write?
            break
          end

          run_once
        end
      rescue Errno::ECONNRESET, IOError => e
        GrpcKit.logger.debug(e.message)
        finish
      end

      def run_once
        return if @stop

        if want_read?
          do_read
        end

        if want_write?
          send
        end
      end

      def finish
        stop
        @io.close
      end

      private

      def stop
        @stop = true
      end

      def invoke
        while (stream = @inflights.pop)
          s = GrpcKit::Transports::ServerTransport.new(session: self, stream: stream)
          @dispatcher.dispatch(stream.headers.path, s)
        end
      end

      def do_read
        receive
      rescue IOError => e
        finish
        raise e
      rescue DS9::Exception => e
        finish
        if DS9::ERR_EOF == e.code
          @peer_shutdowned = true
          return
          # raise EOFError
        end

        raise e
      end

      # `provider` for nghttp2_submit_response
      def on_data_source_read(stream_id, length)
        GrpcKit.logger.debug("on_data_source_read #{stream_id}, lenght=#{length}")

        stream = @streams[stream_id]
        data = @streams[stream_id].pending_send_data.read(length)
        if data.empty? && stream.end_write?
          submit_trailer(stream_id, stream.trailer_data)
          # trailer header
          false
        else
          data
        end
      end

      # nghttp2_session_callbacks_set_on_frame_recv_callback
      def on_frame_recv(frame)
        GrpcKit.logger.debug("on_frame_recv #{frame}")

        case frame
        when DS9::Frames::Data
          stream = @streams[frame.stream_id]

          if frame.end_stream?
            stream.close_remote
          end

          unless stream.inflight
            stream.inflight = true
            @inflights << stream
          end
        when DS9::Frames::Headers
          stream = @streams[frame.stream_id]

          if frame.end_stream?
            stream.close_remote
          end

          # when DS9::Frames::Goaway
          # when DS9::Frames::RstStream
        end

        true
      end

      # nghttp2_session_callbacks_set_on_frame_send_callback
      def on_frame_send(frame)
        GrpcKit.logger.debug("on_frame_send #{frame}")
        case frame
        when DS9::Frames::Data, DS9::Frames::Headers
          stream = @streams[frame.stream_id]
          if frame.end_stream?
            stream.close_local
          end
        end

        true
      end

      # nghttp2_session_callbacks_set_on_frame_not_send_callback
      def on_frame_not_send(frame, reason)
        GrpcKit.logger.debug("on_frame_not_send frame=#{frame}, reason=#{reason}")
        true
      end

      # nghttp2_session_callbacks_set_on_begin_headers_callback
      def on_begin_headers(header)
        stream_id = header.stream_id
        GrpcKit.logger.debug("on_begin_header stream_id=#{stream_id}")

        if @streams[stream_id]
          raise "#{stream_id} is already existed"
        end

        @streams[stream_id] = GrpcKit::Session::Stream.new(stream_id: stream_id)
      end

      # nghttp2_session_callbacks_set_on_header_callback
      def on_header(name, value, frame, _flags)
        GrpcKit.logger.debug("#{name} => #{value}")
        stream = @streams[frame.stream_id]
        stream.add_header(name, value)
      end

      def on_invalid_frame_recv(frame, error_code)
        GrpcKit.logger.debug("on_invalid_frame_recv #{frame} error_code=#{error_code}")
        true
      end

      # nghttp2_session_callbacks_set_on_stream_close_callback
      def on_stream_close(stream_id, error_code)
        GrpcKit.logger.debug("on_stream_close stream_id=#{stream_id}, error_code=#{error_code}")
        stream = @streams.delete(stream_id)
        return unless stream

        stream.close
      end

      # nghttp2_session_callbacks_set_on_data_chunk_recv_callback
      def on_data_chunk_recv(stream_id, data, _flags)
        stream = @streams[stream_id]
        if stream
          stream.pending_recv_data.write(data)
        end
      end
    end
  end
end
