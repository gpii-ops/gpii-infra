task :set_test_protocol do
  @protocol = (@env == "dev" ? "http" : "https")
end

desc '[TEST] Run Locust swarm against Preferences service in current cluster'
task :test_preferences => [:set_vars, :set_test_protocol] do
  sh "#{@exekube_cmd} rake xk[' \
    xk down live/#{@env}/locust && \
    echo \"Waiting for K8s to fully terminate Locust resources...\" && \
    sleep 45 && \
    TF_VAR_locust_target_host=#{@protocol}://preferences.$TF_VAR_domain_name \
    TF_VAR_locust_script=preferences.py \
    TF_VAR_locust_desired_median_response_time=300 \
    TF_VAR_locust_desired_max_response_time=2000 \
    xk up live/#{@env}/locust',skip_secret_mgmt]"
end

desc '[TEST] Run Locust swarm against Flowmanager service in current cluster'
task :test_flowmanager => [:set_vars, :set_test_protocol] do
  sh "#{@exekube_cmd} rake xk[' \
    xk down live/#{@env}/locust && \
    echo \"Waiting for K8s to fully terminate Locust resources...\" && \
    sleep 45 && \
    TF_VAR_locust_target_host=#{@protocol}://flowmanager.$TF_VAR_domain_name \
    TF_VAR_locust_script=flowmanager.py \
    TF_VAR_locust_users=15 \
    TF_VAR_locust_desired_total_rps=5 \
    TF_VAR_locust_desired_median_response_time=500 \
    TF_VAR_locust_desired_max_response_time=3000 \
    xk up live/#{@env}/locust',skip_secret_mgmt]"
end

# vim: et ts=2 sw=2:
