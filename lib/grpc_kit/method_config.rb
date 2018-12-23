# frozen_string_literal: true

module GrpcKit
  MethodConfig = Struct.new(
    :path,
    :ruby_style_method_name,
    :codec,
    :interceptor,
    :service_name,
    :method_name,
    :max_receive_message_size,
    :max_send_message_size,
    :compressor_type,
  ) do
    MAX_SERVER_RECEIVE_MESSAGE_SIZE = 1024 * 1024 * 4
    MAX_SERVER_SEND_MESSAGE_SIZE = 1024 * 1024 * 4
    MAX_CLIENT_RECEIVE_MESSAGE_SIZE = 1024 * 1024 * 4
    MAX_CLIENT_SEND_MESSAGE_SIZE = 1024 * 1024 * 4

    def self.build_for_server(
          path:, ruby_style_method_name:, codec:, service_name:, method_name:, interceptor:,
          max_receive_message_size: MAX_SERVER_RECEIVE_MESSAGE_SIZE, max_send_message_size: MAX_SERVER_SEND_MESSAGE_SIZE, compressor_type: ''
        )
      new(path, ruby_style_method_name, codec, interceptor, service_name, method_name, max_receive_message_size, max_send_message_size, compressor_type)
    end

    def self.build_for_client(
          path:, ruby_style_method_name:, codec:, service_name:, method_name:, interceptor:,
          max_receive_message_size: MAX_CLIENT_RECEIVE_MESSAGE_SIZE, max_send_message_size: MAX_CLIENT_SEND_MESSAGE_SIZE, compressor_type: ''
        )
      new(path, ruby_style_method_name, codec, interceptor, service_name, method_name, max_receive_message_size, max_send_message_size, compressor_type)
    end
  end
end
