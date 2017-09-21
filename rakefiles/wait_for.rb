def wait_for(args, run_with: method(:sh), sleep_secs: 20, max_wait_secs: 15*60)
  ready = false
  total_time = 0
  until ready
    run_with.call(args) do |ok, res|
      if ok
        puts "...ready!"
        ready = true
      else
        puts "...not ready yet. Sleeping #{sleep_secs}s (will give up in #{max_wait_secs - total_time}s)..."
        total_time += sleep_secs
        if total_time >= max_wait_secs
          raise "Max wait time of #{max_wait_secs}s reached. Giving up."
        end
        sleep sleep_secs
      end
    end
  end
end
