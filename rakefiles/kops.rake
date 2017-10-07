task :configure_kops do
  ENV["S3_BUCKET"] = "gpii-kubernetes-state"
  ENV["KOPS_STATE_STORE"] = "s3://#{ENV['S3_BUCKET']}"
end

desc "Configure kubectl to know about cluster"
task :configure_kubectl => :configure_kops do
  sh "kops export kubecfg #{ENV["TF_VAR_cluster_name"]}"
end

desc "[EXPERIMENTAL] [ADVANCED] Edit cluster using kops"
task :kops_edit_cluster => :configure_kops do
  sh "kops edit cluster #{ENV["TF_VAR_cluster_name"]}"
  puts
  puts "Here's what 'kops update cluster' will do:"
  sh "kops update cluster #{ENV["TF_VAR_cluster_name"]} --target terraform"
  sh "kops rolling-update cluster #{ENV["TF_VAR_cluster_name"]}"
  puts
  puts "If that looks right, run:"
  puts
  puts "  KOPS_STATE_STORE=#{ENV["KOPS_STATE_STORE"]} kops update cluster #{ENV["TF_VAR_cluster_name"]} --yes"
  puts "  KOPS_STATE_STORE=#{ENV["KOPS_STATE_STORE"]} kops rolling-update cluster #{ENV["TF_VAR_cluster_name"]} --yes"
  ### actually, i guess it should update state and then recommend running 'rake apply' and THEN rolling-update --yes
  ### KOPS_FEATURE_FLAGS="+DrainAndValidateRollingUpdate"
end
