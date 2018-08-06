task :configure_kops do
  ENV["S3_BUCKET"] = "gpii-kubernetes-state"
  ENV["KOPS_STATE_STORE"] = "s3://#{ENV["S3_BUCKET"]}"
end

desc "Configure kubectl to know about cluster #{ENV["TF_VAR_cluster_name"]}"
task :configure_kubectl => [@tmpdir, :configure_kops] do
  sh "kops export kubecfg #{ENV["TF_VAR_cluster_name"]}"
end

desc "Wait until cluster has converged and is ready to receive components"
task :wait_for_cluster_up => :configure_kubectl do
  puts "Waiting for Kubernetes cluster to be fully up..."
  puts "(You can Ctrl-C out of this safely. You may need to run :destroy afterward.)"

  wait_for("kops validate cluster --name #{ENV["TF_VAR_cluster_name"]}")
end

desc "Wait until cluster has undeployed components and is ready to shut down"
task :wait_for_cluster_down => :configure_kubectl do
  # External-facing Services create ELBs, which will prevent terraform from
  # destroying resources later. Before we delete the Deployments associated
  # with the Service, give the Service time to shut down.
  #
  # Here's the best way I could figure to do that:
  # * Get a list of the names of all ELBs
  # * For each ELB, get the value of the "KubernetesCluster" Tag
  # * Make sure $TF_VAR_cluster_name doesn't appear in the list
  puts "Waiting for load balancers to be fully down..."
  puts "(You can Ctrl-C out of this safely. You may need to re-run :undeploy and/or :destroy afterward.)"
  wait_for("\
    elbs=$(aws elb describe-load-balancers \
      --region us-east-2 \
      --query LoadBalancerDescriptions[*].LoadBalancerName \
      --output text \
    ) && \
    tags=$(for elb in $elbs ; do \
      aws elb describe-tags \
      --region us-east-2 \
      --load-balancer-names $elb \
      --output json | jq -r \
      '.TagDescriptions[].Tags[] | select(.Key==\"KubernetesCluster\") | .Value' \
      ; done \
    ) && \
    [ \"$(echo $tags | grep \"#{ENV["TF_VAR_cluster_name"]}\")\" == \"\" ] \
  ")
  puts "Waiting for load balancer security groups to be fully down..."
  puts "(You can Ctrl-C out of this safely. You may need to re-run :undeploy and/or :destroy afterward.)"
  # We only want to wait for SGs dynamically created by Kubernetes. Permanent
  # SGs (e.g. SGs for nodes and masters) are managed by kops/terraform.
  wait_for("\
    sgs=$(aws ec2 describe-security-groups \
      --region us-east-2 \
      --output json | jq -r \
      '.SecurityGroups[] | select(.Tags != null and .Tags[].Key==\"KubernetesCluster\" and .Tags[].Value == \"#{ENV["TF_VAR_cluster_name"]}\") | select(.Description | startswith(\"Security group for Kubernetes\")) | .GroupId' \
    ) && \
    [ \"$sgs\" == \"\" ] \
  ")
end

desc "[EXPERIMENTAL] [ADVANCED] Edit cluster using kops"
task :kops_edit_cluster => [@tmpdir, :configure_kops] do
  puts "Running a series of 'kops edit' commands."
  puts "Make changes to each config as needed (remember to change the code so new clusters will get the changed config)."
  puts "Or, leave the file alone (quit $EDITOR without making changes)."
  puts
  puts "Running 'kops edit cluster'"
  sh "kops edit cluster #{ENV["TF_VAR_cluster_name"]}"
  puts
  puts "Running 'kops edit instancegroups nodes'"
  sh "kops edit instancegroups nodes --name #{ENV["TF_VAR_cluster_name"]}"
  puts
  puts "Running 'kops edit instancegroups master-us-east-2a'"
  sh "kops edit instancegroups master-us-east-2a --name #{ENV["TF_VAR_cluster_name"]}"
  puts
  puts "Running 'kops edit instancegroups master-us-east-2b'"
  sh "kops edit instancegroups master-us-east-2b --name #{ENV["TF_VAR_cluster_name"]}"
  puts
  puts "Running 'kops edit instancegroups master-us-east-2c'"
  sh "kops edit instancegroups master-us-east-2c --name #{ENV["TF_VAR_cluster_name"]}"
  Rake::Task[:display_rolling_update_cmd].invoke
end

task :display_rolling_update_cmd => [@tmpdir, :configure_kops] do
  puts "If you're happy with your changes, run:"
  puts
  puts "  # Clears existing generated files. NOTE: will clean up other generated files for other modules."
  puts "  rake clean"
  puts
  puts "  # Enact changes."
  puts "  rake apply"
end

task :kops_rolling_update => [@tmpdir, :configure_kops] do
  wait_for(
    "KOPS_FEATURE_FLAGS='+DrainAndValidateRollingUpdate' \
      kops rolling-update cluster #{ENV["TF_VAR_cluster_name"]} --yes",
    max_wait_secs: 60,
  )
end
