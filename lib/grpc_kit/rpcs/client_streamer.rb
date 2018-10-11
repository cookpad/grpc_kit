# frozen_string_literal: true

module GrpcKit
  module Rpcs
    module Client
      class ClientStreamer
        include GrpcKit::Rpcs::Packable

        class SData
          def initialize
            @data = StringIO.new(+'')
            @pos = 0
            @finish = false
            @defered = false
          end

          def end_stream
            @finish = true
          end

          def write(data)
            now = @data.pos
            @data.pos = @pos # move write pos
            v = @data.write(data)
            @pos += v
            @data.pos = now
            v
          end

          def read(size)
            v = @data.read(size)

            if v == '' || v.nil?
              if @finish
                nil # EOF
              else
                @defered = true
                false
              end
            else
              v
            end
          end

          def defered?
            @defered
          end

          attr_writer :defered
        end

        attr_writer :session

        def initialize(path:, protobuf:, authority:, opts: {})
          @path = path
          @protobuf = protobuf
          @authority = authority
          @opts = opts
          @data = SData.new
          @data2 = SData.new
        end

        def invoke(_arg)
          @stream = GrpcKit::Rpcs::Stream.new(
            nil,
            handler: @handler,
            method_name: @method_name,
            protobuf: @protobuf,
            session: @session,
            input: @data,
            path: @path,
          )
        end

        def on_frame_data_recv(stream)
          unless @stream.stream_id == stream.stream_id
            GrpcKit.logger.info("unknow #{stream}")
            return
          end

          bufs = +''
          while (data = stream.consume_read_data)
            compressed, size, buf = unpack(data)

            unless size == buf.size
              raise "inconsistent data: #{buf}"
            end

            if compressed
              raise 'compress option is unsupported'
            end

            bufs << buf
          end
          stream.end_stream

          @stream.output = @protobuf.decode(buf)
        end
      end
    end

    module Server
      class ClientStreamer
        def initialize(handler:, method_name:, protobuf:)
          @handler = handler
          @method_name = method_name
          @protobuf = protobuf
        end

        def invoke(stream)
          ss = GrpcKit::ServerStream.new(stream: stream, protobuf: @protobuf)
          resp = @handler.send(@method_name, ss)
          ss.send_msg(resp)
          stream.end_write
        end
      end
    end
  end
end
