# frozen_string_literal: true

module GrpcKit
  module Interceptors
    module Client
      class Base
        attr_writer :interceptors

        def initialize
          # Cant' get interceptor at definition time...
          @interceptors = nil
        end
      end
    end

    module Server
      class Base
        def initialize(interceptors)
          @interceptors = interceptors
        end
      end
    end
  end
end
