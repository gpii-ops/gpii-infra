require "rake/clean"
require_relative "./wait_for.rb"
import "../rakefiles/kops.rake"

task :configure_kubectl => [@tmpdir, :configure_kops] do
  sh "kops export kubecfg #{ENV["TF_VAR_cluster_name"]}"
end

task :wait_for_cluster_up => :configure_kubectl do
  puts "Waiting for Kubernetes cluster to be fully up..."
  puts "(Note that this will wait potentially forever if the cluster never becomes healthy.)"
  puts "(You can Ctrl-C out of this safely. You may need to run :destroy afterward.)"

  wait_for("kops validate cluster")
end

task :deploy => [:configure_kubectl, :wait_for_cluster_up] do
  sh "kubectl apply -f https://raw.githubusercontent.com/kubernetes/kops/master/addons/kubernetes-dashboard/v1.5.0.yaml"
  sh "kubectl apply -f ../modules/deploy/couchdb-deploy.yml"
  sh "kubectl apply -f ../modules/deploy/couchdb-svc.yml"
  sh "kubectl apply -f ../modules/deploy/dataloader-job.yml"
  sh "kubectl apply -f ../modules/deploy/preferences-deploy.yml"
  sh "kubectl apply -f ../modules/deploy/preferences-svc.yml"
  sh "kubectl apply -f ../modules/deploy/flowmanager-deploy.yml"
  sh "kubectl apply -f ../modules/deploy/flowmanager-svc.yml"
end

# Shut things down via kubernetes, otherwise terraform destroy will get stuck
# on left-behind resources, e.g. ELBs and IGs.
task :undeploy => :configure_kubectl do
  sh "kubectl delete -f ../modules/deploy/flowmanager-svc.yml"
  sh "kubectl delete -f ../modules/deploy/flowmanager-deploy.yml"
  sh "kubectl delete -f ../modules/deploy/preferences-svc.yml"
  sh "kubectl delete -f ../modules/deploy/preferences-deploy.yml"
  sh "kubectl delete -f ../modules/deploy/dataloader-job.yml"
  sh "kubectl delete -f ../modules/deploy/couchdb-svc.yml"
  sh "kubectl delete -f ../modules/deploy/couchdb-deploy.yml"
  # Don't delete dashboard. It doesn't impede anything and it can be useful even in an "undeployed" cluster.
end
