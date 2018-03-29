def wait_for(args, run_with: method(:sh), sleep_secs: 20, max_wait_secs: 15*60, verbose: false)
  ready = false
  output = "UNINITIALIZED OUTPUT"
  total_time = 0
  until ready
    run_with.call(*args) do |ok, res|
      if ok
        puts "...ready!"
        ready = true
        output = res
      else
        puts "...not ready yet. Sleeping #{sleep_secs}s (will give up in #{max_wait_secs - total_time}s)..."
        if verbose
          puts "DEBUG: output from #{run_with} #{args} was:\n#{res}"
        end
        total_time += sleep_secs
        if total_time >= max_wait_secs
          raise "Max wait time of #{max_wait_secs}s reached. Giving up."
        end
        sleep sleep_secs
      end
    end
  end
  return output
end
