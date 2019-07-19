task :test do
  locust_status = 0
  sh "#{@exekube_cmd} rake xk['up live/#{@env}/locust',skip_secret_mgmt]" do |ok, res|
    locust_status = res.exitstatus
  end
  # We want to clean up after Locust even if test failed
  sh "#{@exekube_cmd} rake xk['down live/#{@env}/locust',skip_secret_mgmt]"
  Rake::Task[:destroy_tfstate].reenable
  Rake::Task[:destroy_tfstate].invoke('locust')
  # Exit only if something went wrong to fail the pipeline
  exit locust_status unless locust_status == 0
end

desc "[TEST] Run Locust swarm against Preferences service in current cluster"
task :test_preferences => [:set_vars, :check_destroy_allowed] do
  ENV["TF_VAR_locust_target_host"] = "http://preferences.gpii.svc.cluster.local"
  ENV["TF_VAR_locust_target_app"] = "preferences"
  ENV["TF_VAR_locust_script"] = "preferences.py"
  ENV["TF_VAR_locust_desired_median_response_time"] = "300"
  ENV["TF_VAR_locust_desired_max_response_time"] = "1500"

  Rake::Task[:set_compose_env].reenable
  Rake::Task[:set_compose_env].invoke
  Rake::Task[:test].reenable
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
  Rake::Task[:test].reenable
  Rake::Task[:test].invoke
end

# vim: et ts=2 sw=2:
