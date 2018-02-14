require "open3"
require "rake/clean"
require_relative "./wait_for.rb"
import "../rakefiles/kops.rake"

desc "Wait until cluster has converged enough to create DNS records for GPII components"
task :wait_for_gpii_dns => :find_zone_id do
  preferences_hostname = "preferences.#{ENV["TF_VAR_cluster_name"]}"

  puts "Waiting for DNS records for #{preferences_hostname} to exist..."
  puts "(You can Ctrl-C out of this safely. You may need to re-run :deploy_only afterward.)"

  Rake::Task["wait_for_dns"].invoke(preferences_hostname)
end

desc "Wait until GPII components have been deployed"
task :wait_for_gpii_ready => :configure_kubectl do
  puts "Waiting for GPII components to be fully deployed..."
  puts "(You can Ctrl-C out of this safely. You may need to re-run :deploy_only afterward.)"

  # This is the simplest one-liner I could find to GET a url and return just
  # the status code.
  # http://superuser.com/questions/590099/can-i-make-curl-fail-with-an-exitcode-different-than-0-if-the-http-status-code-i
  #
  # The grep catches a 2xx status code.
  #
  # We use /preferences/carla as a proxy for the overall health of the system.
  # It's not perfect but it's a good start.
  #
  # Currently we only deploy SSL to shared environemnts (stg, prd).
  preferences_url = "http://preferences.#{ENV["TF_VAR_cluster_name"]}/preferences/carla"
  if ENV["TF_VAR_cluster_name"].start_with?("stg.", "prd.")
    preferences_url.gsub! "http://", "https://"
  end
  wait_for("curl --silent --output /dev/stderr --write-out '%{http_code}' '#{preferences_url}' | grep -q ^2")
end

desc "Display some handy info about the cluster"
task :display_cluster_info do
  puts
  puts
  puts "******************************************"
  puts "Congratulations! Your GPII Cloud is ready!"
  puts "******************************************"
  puts
  puts "AWS Dashboard Resource Group:"
  puts "  https://resources.console.aws.amazon.com/r/group#sharedgroup=%7B%22name%22%3A%22#{ ENV["TF_VAR_cluster_name"] }%22%2C%22regions%22%3A%22all%22%2C%22resourceTypes%22%3A%22all%22%2C%22tagFilters%22%3A%5B%7B%22key%22%3A%22KubernetesCluster%22%2C%22values%22%3A%5B%22#{ ENV["TF_VAR_cluster_name"] }%22%5D%7D%5D%7D"
  puts
  puts "Prometheus:"
  puts "  First! Run:"
  puts "    kubectl --namespace monitoring port-forward prometheus-k8s-0 9090 (or k8s-1 and 9091:9090)"
  puts "  Then:"
  puts "    http://localhost:9090 or http://localhost:9091"
  puts
  puts "Alertmanager:"
  puts "  First! Run:"
  puts "    kubectl --namespace monitoring port-forward alertmanager-main-0 9093 (or main-1 and 9094:9093, or main-2 and 9095:9093)"
  puts "  Then:"
  puts "    http://localhost:9093 or http://localhost:9094 or http://localhost:9095"
  puts
  puts "Grafana:"
  puts "  First! Run:"
  puts "    kubectl --namespace monitoring port-forward $(kubectl --namespace monitoring get pods -l 'app == grafana' -o name | sed -e 's,pods/,,g') 3000"
  puts "  Then:"
  puts "    http://localhost:3000"
  puts "      user: admin"
  puts "      pass: admin"
  puts
  puts "Kubernetes Dashboard:"
  puts "  https://#{@api_hostname}/ui"
  puts "    user: admin"
  puts "    pass: `rake display_admin_password`"
  puts
end

task :find_gpii_components => :generate_modules do
  @gpii_components = FileList.new("#{@tmpdir}-modules/deploy/[0-9]*.yml").sort
  Dir.chdir("#{@tmpdir}-modules/deploy/helms/") do
    @gpii_helmcharts = Dir.glob("*").select {|d| File.directory? d }
  end
end

desc "Deploy GPII components to cluster"
task :deploy => [:apply, :configure_kubectl, :wait_for_cluster_up, :init_helm, :find_gpii_components] do
  Rake::Task["deploy_only"].invoke
end

desc "Deploy GPII components to existing cluster without creating/updating infrastructure"
task :deploy_only => [:configure_kubectl, :find_gpii_components] do
  extra_components = [
    "https://raw.githubusercontent.com/kubernetes/dashboard/master/src/deploy/recommended/kubernetes-dashboard.yaml",
  ]
  components = extra_components + @gpii_components
  components.each do |component|
    begin
      wait_for(
        "kubectl --context #{ENV["TF_VAR_cluster_name"]} apply -f #{component}",
        max_wait_secs: 120,
      )
    rescue
      puts "WARNING: Failed to deploy #{component}. Run 'rake deploy_only' to try again. Continuing."
    end
  end

  installed_charts, helm_stdout = Open3.capture2("helm list -q -a")
  installed_charts = installed_charts.split("\n")

  @gpii_helmcharts.each do |chart|
    #TODO upgrade the chart if found

    if installed_charts.include?(chart)
      begin
        wait_for(
          "helm upgrade -f #{@tmpdir}-modules/deploy/helms/#{chart}/custom-values.yaml #{chart} #{@tmpdir}-modules/deploy/helms/#{chart}",
          max_wait_secs: 120,
        )
      rescue
        puts "WARNING: Failed to install helm chart #{chart}. Run 'rake deploy_only' to try again. Continuing."
      end
    else
      begin
        wait_for(
          "helm install --name #{chart} -f #{@tmpdir}-modules/deploy/helms/#{chart}/custom-values.yaml #{@tmpdir}-modules/deploy/helms/#{chart}",
          max_wait_secs: 120,
        )
      rescue
        puts "WARNING: Failed to install helm chart #{chart}. Run 'rake deploy_only' to try again. Continuing."
      end
    end

  end
  Rake::Task["wait_for_gpii_dns"].invoke
  puts "Waiting 60s to give local DNS a chance to catch up..."
  sleep 60
  Rake::Task["wait_for_gpii_ready"].invoke
  Rake::Task["display_cluster_info"].invoke
end

desc "Configure Helm to install Tiller in the cluster #{ENV["TF_VAR_cluster_name"]}"
task :init_helm => [:configure_kubectl] do
  begin
    wait_for(
      "helm init",
      max_wait_secs: 120
    )
  rescue
    puts "WARNING: Failed to initialize helm chart."
  end
end

# Shut things down via kubernetes, otherwise terraform destroy will get stuck
# on left-behind resources, e.g. ELBs and IGs.
desc "Delete GPII components from cluster"
task :undeploy => [:configure_kubectl, :find_gpii_components] do
  # Don't delete dashboard. It doesn't impede anything and it can be useful
  # even in an "undeployed" cluster.
  @gpii_components.reverse.each do |component|
    # Allow deletes to fail, e.g. to clean up a cluster that never got fully deployed.
    begin
      wait_for(
        "kubectl --context #{ENV["TF_VAR_cluster_name"]} delete --ignore-not-found -f #{component}",
        max_wait_secs: 120,
      )
    rescue
      puts "WARNING: Failed to undeploy #{component}. Run 'rake undeploy' to try again. Continuing."
      puts "WARNING: An incomplete undeploy may prevent 'rake destroy' from succeeding."
    end
  end
  @gpii_helmcharts.each do |chart|
    begin
      wait_for(
        "helm delete --name #{chart}",
        max_wait_secs: 120,
      )
    rescue
      puts "WARNING: Failed to delete helm chart #{chart}. Run 'rake undeploy' to try again. Continuing."
    end
  end
  Rake::Task["wait_for_cluster_down"].invoke
end
