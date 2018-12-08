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
@serviceaccount_key_file = ENV["TF_VAR_serviceaccount_key"]
task :configure_serviceaccount, [:use_projectowner_sa] => [:configure_current_project, :set_auth_user_vars] do |taskname, args|
  # TODO: This command is duplicated from exekube's gcp-project-init (and
  # hardcodes 'projectowner' instead of $SA_NAME which is only defined in
  # gcp-project-init). If gcp-project-init becomes idempotent (GPII-2989,
  # https://github.com/exekube/exekube/issues/92), or if this 'keys create'
  # step moves somewhere else in exekube, call this command from that place
  # instead.
  unless File.file?(@serviceaccount_key_file)
    sa_name = args[:use_projectowner_sa] ? "projectowner" : @auth_user_sa_name
    sh "
      gcloud iam service-accounts keys create $TF_VAR_serviceaccount_key \
        --iam-account #{sa_name}@$TF_VAR_project_id.iam.gserviceaccount.com
    "
  end
end

task :destroy_sa_keys, [:use_projectowner_sa] => [:configure_current_project, :set_auth_user_vars] do |taskname, args|
  sa_name = args[:use_projectowner_sa] ? "projectowner" : @auth_user_sa_name
  sh "
    existing_keys=$(gcloud iam service-accounts keys list \
      --iam-account #{sa_name}@$TF_VAR_project_id.iam.gserviceaccount.com \
      --managed-by user | grep -oE \"^[a-z0-9]+\"); \
    current_key=$(cat $TF_VAR_serviceaccount_key 2>/dev/null | jq -r '.private_key_id'); \
    for key in $existing_keys; do \
      if [ \"$key\" != \"$current_key\" ]; then \
        yes | gcloud iam service-accounts keys delete \
          --iam-account #{sa_name}@$TF_VAR_project_id.iam.gserviceaccount.com $key; \
      fi \
    done
  "
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

task :configure_current_project => [@gcp_creds_file] do
  sh "gcloud config set project $TF_VAR_project_id"
end

task :set_auth_user_vars => [@gcp_creds_file] do
  # Setting authenticated user's email into env variable, so it can be
  # accessible in modules: https://issues.gpii.net/browse/GPII-3516
  ENV['TF_VAR_auth_user_email'] = %x{
    gcloud auth list --filter='account!~gserviceaccount.com' --format json |  jq -r '.[].account'
  }.chomp!

  # We build auth user SA from email by replacing non-allowed characters
  # SA name length limit is 30 symbols
  @auth_user_sa_name = ENV['TF_VAR_auth_user_email'].sub("@", "-at-").sub(".", "-")[0..30]
end

