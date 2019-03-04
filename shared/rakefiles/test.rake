task :test do
  sh "#{@exekube_cmd} rake xk['down live/#{@env}/locust',skip_secret_mgmt] || true"
  Rake::Task[:destroy_tfstate].invoke('locust')

  sh "#{@exekube_cmd} sh -c ' \
      RETRIES=10; \
      RETRY_COUNT=1; \
      while [ \"$(kubectl get pods -n locust -o json 2> /dev/null | jq -r .items[] | grep -c .)\" != \"0\" ]; do \
        if [ \"$RETRY_COUNT\" -gt \"$RETRIES\" ]; then \
          echo \"Retry limit reached, giving up!\"; \
          exit 1; \
        fi; \
        echo \"[Try $RETRY_COUNT of $RETRIES] Waiting for K8s to terminate Locust pods...\"; \
        RETRY_COUNT=$(($RETRY_COUNT+1)); \
        sleep 10; \
      done'"

  sh "#{@exekube_cmd} rake xk['up live/#{@env}/locust',skip_secret_mgmt]"
end

desc "[TEST] Run Locust swarm against Preferences service in current cluster"
task :test_preferences => [:set_vars, :check_destroy_allowed] do
  ENV["TF_VAR_locust_target_host"] = "https://preferences.#{ENV["TF_VAR_domain_name"]}"
  ENV["TF_VAR_locust_target_app"] = "preferences"
  ENV["TF_VAR_locust_script"] = "preferences.py"
  ENV["TF_VAR_locust_desired_median_response_time"] = "300"
  ENV["TF_VAR_locust_desired_max_response_time"] = "1500"

  Rake::Task[:set_compose_env].reenable
  Rake::Task[:set_compose_env].invoke
  Rake::Task[:test].invoke
end

desc "[TEST] Run Locust swarm against Flowmanager service in current cluster"
task :test_flowmanager => [:set_vars, :check_destroy_allowed] do
  ENV["TF_VAR_locust_target_host"] = "https://flowmanager.#{ENV["TF_VAR_domain_name"]}"
  ENV["TF_VAR_locust_target_app"] = "flowmanager"
  ENV["TF_VAR_locust_script"] = "flowmanager.py"
  ENV["TF_VAR_locust_users"] = "15"
  ENV["TF_VAR_locust_desired_total_rps"] = "5"
  ENV["TF_VAR_locust_desired_median_response_time"] = "500"
  ENV["TF_VAR_locust_desired_max_response_time"] = "1500"

  Rake::Task[:set_compose_env].reenable
  Rake::Task[:set_compose_env].invoke
  Rake::Task[:test].invoke
end

# vim: et ts=2 sw=2:
