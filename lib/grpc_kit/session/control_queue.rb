# frozen_string_literal: true

module GrpcKit
  module Session
    class ControlQueue
      def initialize(waker: proc { })
        @event_stream = Queue.new
        @waker = waker
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
        @waker.call(:submit_response)
      end

      def submit_headers(id, headers)
        @event_stream.push([:submit_headers, id, headers])
        @waker.call(:submit_headers)
      end

      def resume_data(id)
        @event_stream.push([:resume_data, id])
        @waker.call(:submit_response)
      end
    end
  end
end
