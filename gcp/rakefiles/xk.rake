require "rake/clean"

require_relative "./secrets.rb"
require_relative "./sh_filter.rb"

@exekube_cmd = "/usr/local/bin/xk"

@gcp_creds_file = "/root/.config/gcloud/credentials.db"
task :configure_login => [@gcp_creds_file]
rule @gcp_creds_file do
  # This authenticates to GCP/the `gcloud` command in the normal, interactive
  # way. This is the default method, best for human users.
  sh "gcloud auth login"
end

# This duplicates information in docker-compose.yaml,
# TF_VAR_serviceaccount_key.
@serviceaccount_key_file = "/project/live/#{@env}/secrets/kube-system/owner.json"
task :configure_serviceaccount => [@serviceaccount_key_file]
rule @serviceaccount_key_file => [@gcp_creds_file] do
  # TODO: This command is duplicated from exekube's gcp-project-init (and
  # hardcodes 'projectowner' instead of $SA_NAME which is only defined in
  # gcp-project-init). If gcp-project-init becomes idempotent (GPII-2989,
  # https://github.com/exekube/exekube/issues/92), or if this 'keys create'
  # step moves somewhere else in exekube, call this command from that place
  # instead.
  sh "gcloud iam service-accounts keys create $TF_VAR_serviceaccount_key \
        --iam-account projectowner@$TF_VAR_project_id.iam.gserviceaccount.com"
end

@kubectl_creds_file = "/root/.kube/config"
task :configure_kubectl => [@kubectl_creds_file]
rule @kubectl_creds_file => [@gcp_creds_file] do
  # This duplicates information in terraform code, 'k8s-cluster'
  cluster_name = 'k8s-cluster'
  # This duplicates information in terraform code, 'zone'. Could be a variable with some plumbing.
  zone = 'us-central1-a'
  sh "
    existing_cluster=$(gcloud container clusters list --filter #{cluster_name} --zone #{zone} --project #{ENV["TF_VAR_project_id"]})
    if [ $? == 0 ] && [ \"$existing_cluster\" != \"\" ]; then \
      gcloud container clusters get-credentials #{cluster_name} --zone #{zone} --project #{ENV["TF_VAR_project_id"]}
    fi"
end

# This task is being called from entrypoint.rake and runs inside exekube container.
# It applies infra, secret-mgmt, sets secrets, and then executes arbitrary command from args[:cmd].
# You should not invoke this task directly!
task :xk, [:cmd, :skip_infra, :skip_secret_mgmt] => [@serviceaccount_key_file, @kubectl_creds_file] do |taskname, args|
  @secrets = Secrets.collect_secrets()

  sh "#{@exekube_cmd} up live/#{@env}/infra" unless args[:skip_infra]
  sh "#{@exekube_cmd} up live/#{@env}/secret-mgmt" unless args[:skip_secret_mgmt]

  Secrets.set_secrets(@secrets)

  sh_filter "#{@exekube_cmd} #{args[:cmd]}" if args[:cmd]
end

# vim: et ts=2 sw=2:
