def wait_for(cmd, sleep_secs=20, max_wait_secs=15*60)
  ready = false
  total_time = 0
  until ready
    sh cmd do |ok, res|
      if ok
        puts "...ready!"
        ready = true
      else
        puts "...not ready yet. Sleeping #{sleep_secs}s..."
        total_time += sleep_secs
        if total_time >= max_wait_secs
          puts "Max wait time of #{max_wait_secs}s reached. Giving up."
          return false
        end
        sleep sleep_secs
      end
    end
  end
end
