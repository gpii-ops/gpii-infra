task :configure_kops do
  ENV["S3_BUCKET"] = "gpii-kubernetes-state"
  ENV["KOPS_STATE_STORE"] = "s3://#{ENV["S3_BUCKET"]}"
end

desc "Configure kubectl to know about cluster"
task :configure_kubectl => [@tmpdir, :configure_kops] do
  sh "kops export kubecfg #{ENV["TF_VAR_cluster_name"]}"
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
  puts
  puts "Here's what 'kops update cluster' and 'kops rolling-update cluster' will do:"
  sh "kops update cluster #{ENV["TF_VAR_cluster_name"]} --target terraform"
  sh "kops rolling-update cluster #{ENV["TF_VAR_cluster_name"]}"
  puts
  puts "If that looks right, run:"
  puts
  ###puts "  KOPS_STATE_STORE=#{ENV["KOPS_STATE_STORE"]} kops update cluster #{ENV["TF_VAR_cluster_name"]} --yes"
  puts "  # Clears existing generated files. NOTE: will clean up other generated files for other modules."
  puts "  rake clean"
  puts
  puts "  # Enact changes controlled by Terraform (e.g. instance types used by Masters and Nodes)"
  puts "  rake apply"
  puts
  puts "  # Enact changes controlled by kops (e.g. Kubernetes version) and changes that require instance restarts"
  puts "  # (e.g. instance types used by Masters and Nodes)"
  puts "  KOPS_STATE_STORE=#{ENV["KOPS_STATE_STORE"]} KOPS_FEATURE_FLAGS='+DrainAndValidateRollingUpdate' kops rolling-update cluster #{ENV["TF_VAR_cluster_name"]} --yes"
end
