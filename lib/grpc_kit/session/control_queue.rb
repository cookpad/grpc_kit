# frozen_string_literal: true

module GrpcKit
  module Session
    class ControlQueue
      def initialize
        @event_stream = Queue.new
      end

      # Be nonblocking
      def pop
        if @event_stream.empty?
          nil
        else
          @event_stream.pop(true)
        end
      rescue ThreadError => _
        nil
      end

      def submit_response(id, headers)
        @event_stream.push([:submit_response, id, headers])
      end

      def submit_headers(id, headers)
        @event_stream.push([:submit_headers, id, headers])
      end

      def resume_data(id)
        @event_stream.push([:resume_data, id])
      end
    end
  end
end
