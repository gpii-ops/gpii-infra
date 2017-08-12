def wait_for(cmd)
  sleep_secs = 20
  ready = false
  until ready
    sh cmd do |ok, res|
      if ok
        puts "...ready!"
        ready = true
      else
        puts "...not ready yet. Sleeping #{sleep_secs}s..."
        sleep sleep_secs
      end
    end
  end
end
