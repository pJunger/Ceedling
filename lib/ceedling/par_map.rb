require 'concurrent'

TEST_COMPILE_EXECUTOR = Concurrent::CachedThreadPool.new(PROJECT_COMPILE_THREADS)
# Simplify threadpooling: Either use the same threadpool as for compiling or special case: Test invocation is not threadsafe -> 1 Thread
TEST_EXECUTE_EXECUTOR = if PROJECT_TEST_THREADS > 1 then TEST_COMPILE_EXECUTOR else Concurrent::SingleThreadExecutor.new

def await(futures)
  futures.map {|future| future.value }
end

def await!(futures)
  futures.each {|future| future.value }
end

def wait_or_cancel(futures, timeout)
  futures.map {|future| future.wait_or_cancel(timeout) }
end

def wait_or_cancel!(futures, timeout)
  futures.each {|future| future.wait_or_cancel(timeout) }
end

def par_map(n, things, &block)
  queue = Queue.new
  things.each { |thing| queue << thing }
  threads = (1..n).collect do
    Thread.new do
      begin
        while true
          yield queue.pop(true)
        end
      rescue ThreadError

      end
    end
  end
  threads.each { |t| t.join }
end

