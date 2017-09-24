class Executors
  @@compile_executor = nil
  @@execute_executor = nil

  def self.compile
    if @@compile_executor.nil?
      @@compile_executor = Concurrent::FixedThreadPool.new(PROJECT_COMPILE_THREADS)
    end
    
    @@compile_executor
  end

  def self.execute
    if @@execute_executor.nil?
      @@execute_executor = if PROJECT_TEST_THREADS > 1 then @@compile_executor else Concurrent::SingleThreadExecutor.new end
    end
    
    @@execute_executor
  end
end

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

