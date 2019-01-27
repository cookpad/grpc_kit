# frozen_string_literal: true

require 'grpc_kit/thread_pool/auto_trimmer'

module GrpcKit
  class ThreadPool
    DEFAULT_MAX = 20
    DEFAULT_MIN = 5

    def initialize(max: DEFAULT_MAX, min: DEFAULT_MIN, interval: 30)
      @max_pool_size = max
      @min_pool_size = min
      @shutdown = false
      @tasks = Queue.new
      unless max == min
        @auto_trimmer = AutoTrimmer.new(self, interval: interval).tap(&:start!)
      end

      @spawned = 0
      @workers = []
      @mutex = Mutex.new
      @waiting = 0

      @min_pool_size.times { spawn_thread }
    end

    def register_handler(&block)
      @block = block
      self
    end

    # @return [Bool] scheduling is succes or not
    def schedule(task, &block)
      if task.nil?
        return true
      end

      if @shutdown
        raise "scheduling new task isn't allowed during shutdown"
      end

      @tasks.push(block || task)

      if @mutex.synchronize { (@waiting < @tasks.size) && (@spawned > @min_pool_size) }
        spawn_thread
      end

      true
    end

    def shutdown
      @shutdown = true
      @auto_trimmer.stop if @auto_trimmer
      @waiting.times { @tasks.push(nil) }
    end

    def trim(force = false)
      if @mutex.synchronize { (force || (@waiting > 0)) && (@spawned > @min_pool_size) }
        GrpcKit.logger.debug("Trim worker! Next worker size #{@spawned - 1}")
        @tasks.push(nil)
      end
    end

    private

    def spawn_thread
      @spawned += 1
      worker = Thread.new(@spawned) do |i|
        Thread.current.name = "grpc_kit worker thread #{i}"
        GrpcKit.logger.debug("#{Thread.current.name} started")

        loop do
          if @shutdown
            break
          end

          @mutex.synchronize { @waiting += 1 }
          task = @tasks.pop
          @mutex.synchronize { @waiting -= 1 }
          if task.nil?
            break
          end

          begin
            @block.call(task)
          rescue Exception => e # rubocop:disable Lint/RescueException
            GrpcKit.logger.error("An error occured on top level in worker #{Thread.current.name}: #{e.message} (#{e.class})\n #{Thread.current.backtrace.join("\n")}")
          end
        end

        GrpcKit.logger.debug("worker thread #{Thread.current.name} is stopping")
        @mutex.synchronize do
          @spawned -= 1
          @workers.delete(worker)
        end
      end

      @workers.push(worker)
    end
  end
end
