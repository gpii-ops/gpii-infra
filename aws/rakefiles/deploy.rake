require "yaml"
require "rake/clean"
require "yaml"
require_relative "./wait_for.rb"
import "../rakefiles/kops.rake"
import "../rakefiles/setup_versions.rake"

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

  # Test preferences server
  preferences_url = "preferences.#{ENV["TF_VAR_cluster_name"]}/preferences/carla"
  flowmanager_url = "flowmanager.#{ENV["TF_VAR_cluster_name"]}/carla/settings/%7B%22OS%22:%7B%22id%22:%22linux%22%7D,%22solutions%22:\\[%7B%22id%22:%22org.gnome.desktop.a11y.magnifier%22%7D\\]%7D"

  [preferences_url, flowmanager_url].each do |url|
      if ENV["TF_VAR_cluster_name"].start_with?("prd.", "stg.")
        # This is the simplest one-liner I could find to GET a url and return just
        # the status code.
        # http://superuser.com/questions/590099/can-i-make-curl-fail-with-an-exitcode-different-than-0-if-the-http-status-code-i
        #
        # The grep catches a 2xx status code.
        #
        # We use /preferences/carla as a proxy for the overall health of the system.
        # It's not perfect but it's a good start.
        wait_for("curl --silent --output /dev/stderr --write-out '%{http_code}' 'https://#{url}' | grep -q ^2")
      else
        # For dev environments we need to make sure that plain http is working correctly too
        ['http', 'https'].each do |protocol|
          wait_for("curl -k --silent --output /dev/stderr --write-out '%{http_code}' '#{protocol}://#{url}' | grep -q ^2")
        end
        # We also need to make sure that certificate is issued by Letsencrypt
        wait_for(
          "curl -k -vI 'https://#{url}' 2>&1 | grep 'CN=Fake LE Intermediate X1'",
          sleep_secs: 5,
          max_wait_secs: 20,
        )
      end
  end
end

desc "Wait until production config tests have been completed"
task :wait_for_productionConfigTests_complete => :configure_kubectl do
  Rake::Task["setup_versions"].invoke("../modules/deploy/version.yml")
  puts "Waiting for production config tests to complete..."
  puts "(You can Ctrl-C out of this safely. You may need to re-run :deploy_only afterward.)"

  sh "docker rm -f productionConfigTests || true"
  flowmanager_hostname = "flowmanager.#{ENV["TF_VAR_cluster_name"]}"

  if ENV["TF_VAR_cluster_name"].start_with?("prd.", "stg.")
    flowmanager_hostname = "https://#{flowmanager_hostname}"
  else
    flowmanager_hostname = "http://#{flowmanager_hostname}"
  end

  wait_for("docker run --name productionConfigTests -e GPII_CLOUD_URL='#{flowmanager_hostname}' '#{@versions["flowmanager"]}' node tests/ProductionConfigTests.js")
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
end

desc "Deploy GPII components to cluster"
task :deploy => [:apply, :configure_kubectl, :wait_for_cluster_up, :setup_system_components, :init_helm, :install_charts, :find_gpii_components] do
  Rake::Task["deploy_only"].invoke
end

desc "Deploy GPII components to existing cluster without creating/updating infrastructure"
task :deploy_only => [:configure_kubectl, :install_charts, :find_gpii_components] do
  extra_components = [
    "https://raw.githubusercontent.com/kubernetes/dashboard/master/src/deploy/recommended/kubernetes-dashboard.yaml",
  ]
  components = extra_components + @gpii_components
  components.each do |component|
    begin
      wait_for(
        "kubectl --context #{ENV["TF_VAR_cluster_name"]} apply -f #{component}",
        sleep_secs: 5,
        max_wait_secs: 20,
      )
    rescue
      puts "WARNING: Failed to deploy #{component}. Run 'rake deploy_only' to try again. Continuing."
    end
  end

  Rake::Task["wait_for_gpii_dns"].invoke
  puts "Waiting 60s to give local DNS a chance to catch up..."
  sleep 60
  Rake::Task["wait_for_gpii_ready"].invoke
  Rake::Task["display_cluster_info"].invoke
end

desc "Install Helm charts in the cluster #{ENV["TF_VAR_cluster_name"]}"
task :install_charts => [:configure_kubectl, :generate_modules, :setup_system_components, :init_helm] do
  Dir.chdir("#{@tmpdir}-modules/deploy/helms/") do
    @gpii_helmcharts = Dir.glob("*").select {|d| File.directory? d }
  end

  installed_charts = `helm list -q -a`
  installed_charts = installed_charts.split("\n")
  @gpii_helmcharts.each do |chart|
    chart_config = YAML.load_file("#{@tmpdir}-modules/deploy/helms/#{chart}/custom-values.yaml")
    # Extracting chart name and namespace from chart-metadata
    if chart_config['chart-metadata'] && chart_config['chart-metadata']['name']
      chart_name = chart_config['chart-metadata']['name']
    else
      chart_name = chart.match(/^\d+\-(.*)/)[1]
    end
    if chart_config['chart-metadata'] && chart_config['chart-metadata']['namespace']
      chart_namespace = chart_config['chart-metadata']['namespace']
    else
      chart_namespace = 'default'
    end

    if installed_charts.include?(chart_name)
      begin
        wait_for(
          "helm upgrade --namespace #{chart_namespace} --recreate-pods -f #{@tmpdir}-modules/deploy/helms/#{chart}/custom-values.yaml #{chart_name} #{@tmpdir}-modules/deploy/helms/#{chart}",
          sleep_secs: 5,
          max_wait_secs: 60,
        )
      rescue
        puts "WARNING: Failed to install helm chart #{chart}. Run 'rake deploy_only' to try again. Continuing."
      end
    else
      begin
        wait_for(
          "helm install --name #{chart_name} --namespace #{chart_namespace} -f #{@tmpdir}-modules/deploy/helms/#{chart}/custom-values.yaml #{@tmpdir}-modules/deploy/helms/#{chart}",
          sleep_secs: 5,
          max_wait_secs: 60,
        )
      rescue
        puts "WARNING: Failed to install helm chart #{chart}. Run 'rake deploy_only' to try again. Continuing."
      end
    end
  end
end

desc "Configure default RBAC roles, namespaces, Tiller account, and other system components in the cluster #{ENV["TF_VAR_cluster_name"]}"
task :setup_system_components => [:configure_kubectl] do
  begin
    wait_for(
      "kubectl --context #{ENV["TF_VAR_cluster_name"]} apply -f ../modules/deploy/system/",
      sleep_secs: 5,
      max_wait_secs: 20,
    )
  rescue
    puts "WARNING: Failed to configure system components."
  end
end

desc "Configure Helm to install Tiller in the cluster #{ENV["TF_VAR_cluster_name"]}"
task :init_helm => [:configure_kubectl, :setup_system_components] do
  begin
    wait_for(
      "helm init --service-account tiller",
      sleep_secs: 5,
      max_wait_secs: 20,
    )
  rescue
    puts "WARNING: Failed to initialize Helm."
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
        sleep_secs: 5,
        max_wait_secs: 20,
      )
    rescue
      puts "WARNING: Failed to undeploy #{component}. Run 'rake undeploy' to try again. Continuing."
      puts "WARNING: An incomplete undeploy may prevent 'rake destroy' from succeeding."
    end
  end

  Dir.chdir("#{@tmpdir}-modules/deploy/helms/") do
    @gpii_helmcharts = Dir.glob("*").select {|d| File.directory? d }
  end
  @gpii_helmcharts.each do |chart|
    begin
      wait_for(
        "helm delete #{chart}",
        sleep_secs: 5,
        max_wait_secs: 20,
      )
    rescue
      puts "WARNING: Failed to delete helm chart #{chart}. Run 'rake undeploy' to try again. Continuing."
    end
  end
  begin
    wait_for(
      "kubectl --context #{ENV["TF_VAR_cluster_name"]} delete --ignore-not-found -f ../modules/deploy/system/",
      sleep_secs: 5,
      max_wait_secs: 20,
    )
  rescue
    puts "WARNING: Failed to configure system components."
  end
  Rake::Task["wait_for_cluster_down"].invoke
end

desc "Run an interactive shell on a container inside the cluster"
task :run_interactive => :configure_kubectl do
  sh "kubectl run -i -t alpine --image=alpine --restart=Never"
end

desc "Re-attach to a shell started with :run_interactive"
task :attach_interactive => :configure_kubectl do
  sh "kubectl attach -i -t alpine"
end

desc "Delete the interactive shell running inside the cluster"
task :delete_interactive => :configure_kubectl do
  sh "kubectl delete pod alpine"
end
