# frozen_string_literal: true

require 'grpc_kit/rpc_dispatcher/auto_trimmer'
require 'grpc_kit/transport/server_transport'
require 'grpc_kit/stream/server_stream'

module GrpcKit
  class RpcDispatcher
    DEFAULT_MAX = 20
    DEFAULT_MIN = 5

    # @param rpcs [Hash<String,GrpcKit::RpcDesc>]
    # @param min [Integer] A mininum thread pool size
    # @param max [Integer] A maximum thread pool size
    # @param interval [Integer] An interval time of calling #trim
    def initialize(rpcs, max: DEFAULT_MAX, min: DEFAULT_MIN, interval: 30)
      @rpcs = rpcs
      @max_pool_size = max
      @min_pool_size = min
      unless max == min
        @auto_trimmer = AutoTrimmer.new(self, interval: interval).tap(&:start!)
      end

      @shutdown = false
      @tasks = Queue.new
      @spawned = 0
      @workers = []
      @mutex = Mutex.new

      @min_pool_size.times { spawn_thread }
    end

    # @param task [Object] task to dispatch
    def schedule(task)
      if task.nil?
        return
      end

      if @shutdown
        raise "scheduling new task isn't allowed during shutdown"
      end

      @tasks.push(task)
      if @tasks.size > 1 && @mutex.synchronize { @spawned < @max_pool_size }
        spawn_thread
      end
    end

    def shutdown
      @shutdown = true
      @auto_trimmer.stop if @auto_trimmer
      @max_pool_size.times { @tasks.push(nil) }
    end

    def trim(force = false)
      if (force || @tasks.empty?) && @mutex.synchronize { @spawned > @min_pool_size }
        GrpcKit.logger.debug("Decrease RpcDipatcher's worker. Next worker size is #{@spawned - 1}")
        @tasks.push(nil)
      end
    end

    private

    def dispatch(stream, control_queue)
      transport = GrpcKit::Transport::ServerTransport.new(control_queue, stream)
      server_stream = GrpcKit::Stream::ServerStream.new(transport)
      path = stream.headers.path

      rpc = @rpcs[path]
      unless rpc
        e = GrpcKit::Errors::Unimplemented.new(path)
        server_stream.send_status(status: e.code, msg: e.message)
        return
      end

      server_stream.invoke(rpc)
    end

    def spawn_thread
      @spawned += 1
      worker = Thread.new(@spawned) do |i|
        Thread.current.name = "RpcDispatcher #{i}"
        GrpcKit.logger.debug("#{Thread.current.name} started")

        loop do
          if @shutdown
            break
          end

          task = @tasks.pop
          if task.nil?
            break
          end

          begin
            dispatch(task[0], task[1])
          rescue Exception => e # rubocop:disable Lint/RescueException
            GrpcKit.logger.error("An error occured on top level in worker #{Thread.current.name}: #{e.message} (#{e.class})\n #{e.backtrace.join("\n")}")
          end
        end

        GrpcKit.logger.debug("#{Thread.current.name} stopped")
        @mutex.synchronize do
          @spawned -= 1
          @workers.delete(worker)
        end
      end

      @workers.push(worker)
    end
  end
end
