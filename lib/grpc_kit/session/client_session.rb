# frozen_string_literal: true

require 'ds9'
require 'forwardable'
require 'grpc_kit/session/stream'
require 'grpc_kit/session/send_buffer'

module GrpcKit
  module Session
    class ClientSession < DS9::Client
      class ConnectionClosing < StandardError; end

      extend Forwardable

      MAX_STREAM_ID = 2**31 - 1

      delegate %i[send_event recv_event] => :@io

      # @param io [GrpcKit::Session::IO]
      # @param opts [Hash]
      def initialize(io, opts = {})
        super() # initialize DS9::Session

        @io = io
        @streams = {}
        @opts = opts
        @draining = false
        @stop = false
        @no_write_data = false
        @mutex = Mutex.new
      end

      # @param headers [Hash<String,String>]
      # @return [void]
      def send_request(headers)
        if @draining
          raise ConnectionClosing, "You can't send new request. becuase this connection will shuting down"
        end

        stream = GrpcKit::Session::Stream.new(stream_id: 0) # set later
        stream_id = submit_request(headers, stream.pending_send_data).to_i
        stream.stream_id = stream_id
        @streams[stream_id] = stream
        @no_write_data = false
        stream
      end

      # @param stream_id [Integer]
      # @return [void]
      def start(stream_id)
        stream = @streams[stream_id]
        return unless stream # stream might have already close

        loop do
          if (!want_read? && !want_write?) || stream.close?
            break
          end

          run_once
        end
      rescue Errno::ECONNRESET, IOError => e
        GrpcKit.logger.debug(e.message)
        shutdown
      end

      # @return [void]
      def run_once
        @mutex.synchronize do
          return if @stop

          if @draining && @drain_time < Time.now
            raise 'trasport is closing'
          end

          if @no_write_data && !@streams.empty?
            @io.wait_readable

            if want_read?
              do_read
            end
          else
            rs, ws = @io.select
            if !rs.empty? && want_read?
              do_read
            end

            if !ws.empty? && want_write?
              send
            end
          end
        end
      end

      private

      def shutdown
        @stop = true
        @io.close
      end

      def do_read
        receive
      rescue IOError => e
        shutdown
        raise e
      rescue DS9::Exception => e
        GrpcKit.logger.debug(e.message)
        if DS9::ERR_EOF == e.code
          raise EOFError, e
        end

        raise e
      end

      # nghttp2_session_callbacks_set_on_frame_send_callback
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
          end

        when DS9::Frames::Headers
          stream = @streams[frame.stream_id]

          if frame.end_stream?
            stream.close_remote
          end
        when DS9::Frames::Goaway
          handle_goaway(frame)
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
            @no_write_data = @streams.all? { |_, v| v.close_local? }
          end
        end

        true
      end

      # nghttp2_session_callbacks_set_on_stream_close_callback
      def on_stream_close(stream_id, error_code)
        GrpcKit.logger.debug("on_stream_close stream_id=#{stream_id}, error_code=#{error_code}")
        stream = @streams.delete(stream_id)
        unless stream
          GrpcKit.logger.warn("on_stream_close stream_id=#{stream_id} not remain on ClientSession")
          return
        end
        stream.close
      end

      # nghttp2_session_callbacks_set_on_data_chunk_recv_callback
      def on_data_chunk_recv(stream_id, data, _flags)
        stream = @streams[stream_id]
        if stream
          stream.pending_recv_data.write(data)
        end
      end

      # # for nghttp2_session_callbacks_set_on_frame_not_send_callback
      # def on_frame_not_send(frame, reason)
      # end

      # for nghttp2_session_callbacks_set_on_header_callback
      def on_header(name, value, frame, _flags)
        GrpcKit.logger.debug("#{name} => #{value}")
        stream = @streams[frame.stream_id]
        stream.add_header(name, value)
      end

      # # for nghttp2_session_callbacks_set_on_begin_headers_callback
      # def on_begin_header(name, value, frame, flags)
      # end

      # # for nghttp2_session_callbacks_set_on_begin_frame_callback
      # def on_begin_frame(frame_header)
      # end

      # # for nghttp2_session_callbacks_set_on_invalid_frame_recv_callback
      # def on_invalid_frame_recv(frame, error_code)
      # end

      def handle_goaway(frame)
        # shutdown notice
        last_stream_id = frame.last_stream_id
        if last_stream_id == MAX_STREAM_ID && frame.error_code == DS9::NO_ERROR
          @draining = true
          @drain_time = Time.now + 10 # XXX
          @streams.each_value(&:drain)
        end

        @streams.each do |id, stream|
          if id > last_stream_id
            stream.close
          end
        end

        shutdown if @streams.empty?
      end
    end
  end
end
