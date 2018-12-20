# frozen_string_literal: true

require 'grpc_kit'
require_relative 'call_stream'

class LoggingInterceptor < GRPC::ServerInterceptor
  def request_response(request: nil, call: nil, method: nil)
    now = Time.now.to_i
    GrpcKit.logger.info("Started request #{request}, method=#{method.name}, service_name=#{method.receiver.class.service_name}")
    yield(request, call).tap do
      GrpcKit.logger.info("Elapsed Time: #{Time.now.to_i - now}")
    end
  end

  def client_streamer(call: nil, method: nil)
    GrpcKit.logger.info("Started request method=#{method.name}, service_name=#{method.receiver.class.service_name}")
    yield(LoggingStream.new(call))
  end

  def server_streamer(call: nil, method: nil, **)
    GrpcKit.logger.info("Started request method=#{method.name}, service_name=#{method.receiver.class.service_name}")
    yield(LoggingStream.new(call))
  end

  def bidi_streamer(call: nil, method: nil, **)
    GrpcKit.logger.info("Started request method=#{method.name}, service_name=#{method.receiver.class.service_name}")
    yield(LoggingStream.new(call))
  end

  class LoggingStream < CallStream
    def send_msg(msg)
      GrpcKit.logger.info("logging interceptor send #{msg.inspect}")
      super
    end

    def recv
      super.tap do |v|
        GrpcKit.logger.info("logging interceptor recv #{v.inspect}")
      end
    end
  end
end
