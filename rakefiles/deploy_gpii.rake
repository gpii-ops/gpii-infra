require "rake/clean"

task :configure_kubectl => TMPDIR do
  ENV["S3_BUCKET"] = "gpii-kubernetes-state"
  ENV["KOPS_STATE_STORE"] = "s3://#{ENV['S3_BUCKET']}"
  sh "kops export kubecfg #{ENV["TF_VAR_cluster_name"]}"
end

task :deploy => :configure_kubectl do
  ENV["S3_BUCKET"] = "gpii-kubernetes-state"
  ENV["KOPS_STATE_STORE"] = "s3://#{ENV['S3_BUCKET']}"
  sh "kubectl apply -f https://raw.githubusercontent.com/kubernetes/kops/master/addons/kubernetes-dashboard/v1.5.0.yaml"
  sh "kubectl apply -f ../deploy_gpii/couchdb-deploy.yml"
  sh "kubectl apply -f ../deploy_gpii/couchdb-svc.yml"
  sh "kubectl apply -f ../deploy_gpii/dataloader-job.yml"
  sh "kubectl apply -f ../deploy_gpii/preferences-deploy.yml"
  sh "kubectl apply -f ../deploy_gpii/preferences-svc.yml"
  sh "kubectl apply -f ../deploy_gpii/flowmanager-deploy.yml"
  sh "kubectl apply -f ../deploy_gpii/flowmanager-svc.yml"
end

task :undeploy => :configure_kubectl do
  ENV["S3_BUCKET"] = "gpii-kubernetes-state"
  ENV["KOPS_STATE_STORE"] = "s3://#{ENV['S3_BUCKET']}"
  sh "kubectl delete -f ../deploy_gpii/flowmanager-svc.yml"
  sh "kubectl delete -f ../deploy_gpii/flowmanager-deploy.yml"
  sh "kubectl delete -f ../deploy_gpii/preferences-svc.yml"
  sh "kubectl delete -f ../deploy_gpii/preferences-deploy.yml"
  sh "kubectl delete -f ../deploy_gpii/dataloader-job.yml"
  sh "kubectl delete -f ../deploy_gpii/couchdb-svc.yml"
  sh "kubectl delete -f ../deploy_gpii/couchdb-deploy.yml"
  # sh "kubectl delete -f https://raw.githubusercontent.com/kubernetes/kops/master/addons/kubernetes-dashboard/v1.5.0.yaml"
end
