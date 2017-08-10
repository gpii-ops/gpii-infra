require "rake/clean"
import "../rakefiles/kops.rake"

task :configure_kubectl => [@tmpdir, :configure_kops] do
  sh "kops export kubecfg #{ENV["TF_VAR_cluster_name"]}"
end

task :deploy => :configure_kubectl do
  sh "kubectl apply -f https://raw.githubusercontent.com/kubernetes/kops/master/addons/kubernetes-dashboard/v1.5.0.yaml"
  sh "kubectl apply -f ../deploy_gpii/couchdb-deploy.yml"
  sh "kubectl apply -f ../deploy_gpii/couchdb-svc.yml"
  sh "kubectl apply -f ../deploy_gpii/dataloader-job.yml"
  sh "kubectl apply -f ../deploy_gpii/preferences-deploy.yml"
  sh "kubectl apply -f ../deploy_gpii/preferences-svc.yml"
  sh "kubectl apply -f ../deploy_gpii/flowmanager-deploy.yml"
  sh "kubectl apply -f ../deploy_gpii/flowmanager-svc.yml"
end

# Shut things down via kubernetes, otherwise terraform destroy will get stuck
# on left-behind resources, e.g. ELBs and IGs.
task :undeploy => :configure_kubectl do
  sh "kubectl delete -f ../deploy_gpii/flowmanager-svc.yml"
  sh "kubectl delete -f ../deploy_gpii/flowmanager-deploy.yml"
  sh "kubectl delete -f ../deploy_gpii/preferences-svc.yml"
  sh "kubectl delete -f ../deploy_gpii/preferences-deploy.yml"
  sh "kubectl delete -f ../deploy_gpii/dataloader-job.yml"
  sh "kubectl delete -f ../deploy_gpii/couchdb-svc.yml"
  sh "kubectl delete -f ../deploy_gpii/couchdb-deploy.yml"
  # Don't delete dashboard. It doesn't impede anything and it can be useful even in an "undeployed" cluster.
end
