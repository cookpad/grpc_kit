# frozen_string_literal: true

require 'grpc_kit/transport/packable'

module GrpcKit
  module Transport
    class ClientTransport
      include GrpcKit::Transport::Packable

      # @param session [GrpcKit::Session::ClientSession]
      def initialize(session)
        @session = session
        @stream = nil # set later
      end

      # @param data [String]
      # @param headers [Hash<String, String>]
      # @param last [Boolean]
      # @return [void]
      def start_request(data, headers, last: false)
        @stream = @session.send_request(headers)
        write_data(data, last: last)
      end

      # @return [void]
      def close_and_flush
        @stream.end_write
        send_data

        @session.start(@stream.stream_id)
        @stream.end_read
        @deferred = false
      end

      # @param buf [String]
      # @param last [Boolean]
      # @return [void]
      def write_data(buf, last: false)
        write(@stream.pending_send_data, pack(buf), last: last)
        send_data
      end

      # @param last [Boolean]
      # @return [nil,String]
      def read_data(last: false)
        data_in_buffer = unpack(nil) 
        return data_in_buffer if data_in_buffer

        unpack(recv_data(last: last))
      end

      # @param last [Boolean]
      # @return [nil,String]
      def read_data_nonblock(last: false)
        data_in_buffer = unpack(nil) 
        return data_in_buffer if data_in_buffer

        data = nonblock_recv_data(last: last)
        if data == :wait_readable
          :wait_readable
        else
          unpack(data)
        end
      end

      # @return [Hash<String,String>]
      def recv_headers
        wait_close
        @stream.headers
      end

      private

      def wait_close
        # XXX: wait until half close (remote) to get grpc-status
        until @stream.close_remote?
          @session.run_once
        end
      end

      def write(stream, buf, last: false)
        stream.write(buf, last: last)
      end

      def nonblock_recv_data(last: false)
        data = @stream.read_recv_data(last: last, blocking: false)
        return data if data.is_a?(String)
        return nil unless data

        :wait_readable
      end

      def recv_data(last: false)
        loop do
          # FIXME: GrpcKit::Client isn't threaded, this cannot be blocked to trigger ClientSession#run_once appropriately
          #        but run_once would block while no outbound requests. Could be problematic on BiDi calls.
          data = @stream.read_recv_data(last: last, blocking: false)
          case data
          when :wait_readable
            @session.run_once
          when String
            return data
          when nil
            return nil
          end
        end
      end

      def send_data
        if @stream.pending_send_data.need_resume?
          @session.resume_data(@stream.stream_id)
        end

        @session.run_once
      end
    end
  end
end
