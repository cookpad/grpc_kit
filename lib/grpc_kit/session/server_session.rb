# frozen_string_literal: true

require 'ds9'
require 'forwardable'
require 'grpc_kit/session/stream'
require 'grpc_kit/session/drain_controller'
require 'grpc_kit/stream/server_stream'
require 'grpc_kit/transport/server_transport'
require 'grpc_kit/session/send_buffer'

module GrpcKit
  module Session
    class ServerSession < DS9::Server
      extend Forwardable

      delegate %i[send_event recv_event] => :@io

      # @param io [GrpcKit::Session::IO]
      # @param dispatcher [GrpcKit::Server]
      def initialize(io, dispatcher)
        super() # initialize DS9::Session

        @io = io
        @streams = {}
        @stop = false
        @dispatcher = dispatcher
        @inflights = []
        @drain_controller = GrpcKit::Session::DrainController.new
      end

      # @return [void]
      def start
        loop do
          invoke

          if @streams.empty?
            unless @io.wait_readable
              shutdown
              break
            end
          end

          continue = run_once
          break unless continue
        end
      ensure
        GrpcKit.logger.debug('Finish server session')
      end

      # @return [bool] return session can continue
      def run_once
        if @stop || !(want_read? || want_write?)
          # it could be called twice
          @streams.each_value(&:close)
          return false
        end

        if @drain_controller.start_draining?
          if @streams.empty?
            shutdown
            return false
          end

          @drain_controller.next(self)
        end

        rs, ws = @io.select

        if !rs.empty? && want_read?
          do_read
        end

        if !ws.empty? && want_write?
          send
        end

        true
      rescue Errno::ECONNRESET, IOError => e
        GrpcKit.logger.debug(e.message)
        shutdown
        false
      end

      # @return [void]
      def drain
        @drain_controller.start_draining
      end

      # @return [void]
      def shutdown
        stop
        @io.close
      rescue StandardError => e
        GrpcKit.logger.debug(e)
      end

      private

      def stop
        @stop = true
      end

      def invoke
        while (stream = @inflights.pop)
          t = GrpcKit::Transport::ServerTransport.new(self, stream)
          th = GrpcKit::Stream::ServerStream.new(t)
          @dispatcher.dispatch(stream.headers.path, th)
        end
      end

      def do_read
        receive
      rescue DS9::Exception => e
        shutdown

        case e.code
        when DS9::ERR_EOF
          GrpcKit.logger.debug('The peer performed a shutdown on the connection')
        when DS9::ERR_BAD_CLIENT_MAGIC
          GrpcKit.logger.error('Invalid client magic was received')
        else
          raise "#{e.message}. code=#{e.code}"
        end
      end

      # `provider` for nghttp2_submit_response
      def on_data_source_read(stream_id, length)
        GrpcKit.logger.debug("on_data_source_read #{stream_id}, lenght=#{length}")

        stream = @streams[stream_id]
        data = @streams[stream_id].pending_send_data.read(length)
        if data.nil?
           unless stream.trailer_data.empty?
             submit_trailer(stream_id, stream.trailer_data)
           end
          # trailer header
          false
        else
          data
        end
      end

      # nghttp2_session_callbacks_set_on_frame_recv_callback
      def on_frame_recv(frame)
        GrpcKit.logger.debug("on_frame_recv #{frame}") # Too many call

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
          if frame.end_stream?
            stream = @streams[frame.stream_id]
            stream.close_remote
          end
        when DS9::Frames::Ping
          if frame.ping_ack?
            GrpcKit.logger.debug('ping ack is received')
            # nghttp2 can't send any data once server sent actaul GoAway(not shutdown notice) frame.
            # We want to send data in case of ClientStreamer or BidiBstreamer which they are sending data in same stream
            # So we have to wait to send actual GoAway frame untill timeout or something
            # @drain_controller.recv_ping_ack
          end
          # when DS9::Frames::Goaway
          # when DS9::Frames::RstStream
        end

        true
      end

      # nghttp2_session_callbacks_set_on_frame_send_callback
      def on_frame_send(frame)
        GrpcKit.logger.debug("on_frame_send #{frame}") # Too many call
        case frame
        when DS9::Frames::Data, DS9::Frames::Headers
          if frame.end_stream?
            stream = @streams[frame.stream_id]
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
        GrpcKit.logger.debug("#{name} => #{value}") # Too many call
        stream = @streams[frame.stream_id]
        stream.add_header(name, value)
      end

      def on_invalid_frame_recv(frame, error_code)
        GrpcKit.logger.debug("on_invalid_frame_recv #{frame} error_code=#{error_code}")
        true
      end

      # nghttp2_session_callbacks_set_on_stream_close_callback
      def on_stream_close(stream_id, error_code)
        if error_code != DS9::NO_ERROR
          GrpcKit.logger.debug("on_stream_close stream_id=#{stream_id}, error_code=#{error_code}")
        end

        stream = @streams.delete(stream_id)
        stream.close if stream

        if @drain
          if @streams.empty?
            shutdown
          end
        end
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
