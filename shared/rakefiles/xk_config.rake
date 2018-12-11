
@gcp_creds_file = "/root/.config/gcloud/credentials.db"
task :configure_login => [@gcp_creds_file]
rule @gcp_creds_file do
  # This authenticates to GCP/the `gcloud` command in the normal, interactive
  # way. This is the default method, best for human users.
  sh "gcloud auth login"
end

# A more rake-ish way to create this file would be:
#
#   task :configure_serviceaccount => [@serviceaccount_key_file]
#   rule @serviceaccount_key_file => [@gcp_creds_file] do ... end
#
# However, that logic would force creation of a new @serviceaccount_key_file
# (and a new Serviceaccount Key) whenever @gcp_creds_file changes. This is not
# what we want, i.e. don't create a new Key/key file when @gcp_creds_file
# changes because of :configure_kubectl.
@serviceaccount_key_file = "/project/live/#{ENV['ENV']}/secrets/kube-system/owner.json"
task :configure_serviceaccount => [@gcp_creds_file] do
  # TODO: This command is duplicated from exekube's gcp-project-init (and
  # hardcodes 'projectowner' instead of $SA_NAME which is only defined in
  # gcp-project-init). If gcp-project-init becomes idempotent (GPII-2989,
  # https://github.com/exekube/exekube/issues/92), or if this 'keys create'
  # step moves somewhere else in exekube, call this command from that place
  # instead.
  unless File.file?(@serviceaccount_key_file)
    sh "
      gcloud iam service-accounts keys create #{@serviceaccount_key_file} \
        --iam-account projectowner@$TF_VAR_project_id.iam.gserviceaccount.com
    "
  end
end

@default_creds_file = "/root/.config/gcloud/application_default_credentials.json"
task :configure_app_default_login => [@default_creds_file]
rule @default_creds_file do
  # This retrieves application-default credentials using interactive auth,
  # only in case service account credentials are not present.
  unless File.file?(@serviceaccount_key_file)
    sh "gcloud auth application-default login"
  end
end

@kubectl_creds_file = "/root/.kube/config"
task :configure_kubectl => [@kubectl_creds_file]
rule @kubectl_creds_file => [@gcp_creds_file] do
  # This duplicates information in terraform code, 'k8s-cluster'
  cluster_name = 'k8s-cluster'
  # This duplicates information in terraform code, 'zone'. Could be a variable with some plumbing.
  zone = 'us-central1-a'
  sh "
    existing_cluster=$(gcloud container clusters list --filter #{cluster_name} --zone #{zone} --project $TF_VAR_project_id)
    if [ $? == 0 ] && [ \"$existing_cluster\" != \"\" ]; then \
      gcloud container clusters get-credentials #{cluster_name} --zone #{zone} --project $TF_VAR_project_id
    fi"
end

task :configure => [@gcp_creds_file, @default_creds_file, @kubectl_creds_file] do
  sh "gcloud config set project $TF_VAR_project_id"
  # We need to set service account key var only if SA credentials are present locally.
  # In case var is unset, application-default credentials will be used.
  ENV['TF_VAR_serviceaccount_key'] = File.file?(@serviceaccount_key_file) ? @serviceaccount_key_file : ''
end
