# frozen_string_literal: true

require 'grpc_kit'
require 'forwardable'

class CallStream < GrpcKit::Call
  include Enumerable
  extend Forwardable
  delegate %i[send_msg recv] => :@inner

  # @params call [GrpcKit::Call]
  def initialize(inner)
    @inner = inner
  end

  def each
    loop { yield(recv) }
  end

  def method_missing(name, *args, &block)
    @inner.public_send(name, *args, &block)
  end
end
