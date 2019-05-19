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
  Rake::Task[:activate_serviceaccount].invoke
end

# We need separate task to activate service account from key file
# so we can call it directly after restoring saved
# @serviceaccount_key_file in :configure_serviceaccount_ci_restore
task :activate_serviceaccount => [@serviceaccount_key_file] do
  sh "
    gcloud auth activate-service-account \
      --key-file #{@serviceaccount_key_file} \
      --project $TF_VAR_project_id
  "
end

task :destroy_sa_keys, [:use_projectowner_sa] => [:configure_current_project, :configure_extra_tf_vars, :set_auth_user_vars] do |taskname, args|
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

@app_default_creds_file = "/root/.config/gcloud/application_default_credentials.json"
task :configure_app_default_login => [@app_default_creds_file]
rule @app_default_creds_file do
  # This retrieves application-default credentials using interactive auth,
  # only in case service account credentials are not present.
  unless File.file?(@serviceaccount_key_file)
    sh "gcloud auth application-default login"
  else
    puts "SA credentials are present locally, skipping app-default login..."
  end
end

@kubectl_creds_file = "/root/.kube/config"
task :configure_kubectl => [@kubectl_creds_file]
rule @kubectl_creds_file => [@gcp_creds_file] do
  # This duplicates information in terraform code, 'k8s-cluster'
  cluster_name = "k8s-cluster"
  sh "
    existing_cluster_zone=$(gcloud container clusters list --filter #{cluster_name} --project #{ENV["TF_VAR_project_id"]} --format json | jq -er '.[0].zone')
    if [ $? == 0 ]; then \
      gcloud container clusters get-credentials #{cluster_name} --zone ${existing_cluster_zone} --project #{ENV["TF_VAR_project_id"]}
    fi"
end

task :configure_current_project do
  sh "gcloud config set project $TF_VAR_project_id"
end

task :configure_extra_tf_vars do
  # We need to set service account key var only if SA credentials are present locally.
  # In case var is unset, application-default credentials will be used.
  ENV["TF_VAR_serviceaccount_key"] = File.file?(@serviceaccount_key_file) ? @serviceaccount_key_file : ""
  # Setting authenticated user's email into env variable, so it can be
  # accessible in modules: https://issues.gpii.net/browse/GPII-3516
  # In case auth user data is missing, it will be set to empty string
  unless ENV["TF_VAR_auth_user_email"]
    ENV["TF_VAR_auth_user_email"] = %x{
      gcloud auth list --filter='account!~gserviceaccount.com' --format json |  jq -r '[.[].account][0]'
    }.chomp!
    ENV["TF_VAR_auth_user_email"] = "" if ENV["TF_VAR_auth_user_email"] == "null"
  end
end

task :configure_secrets do
  decrypt_with_key_from_region = ENV["TF_VAR_decrypt_with_key_from_region"]
  @secrets = Secrets.new(
      ENV["TF_VAR_project_id"],
      ENV["TF_VAR_infra_region"],
      decrypt_with_key_from_region=decrypt_with_key_from_region)
  @secrets.collect_secrets()
end

task :set_secrets do
  @secrets.set_secrets()
end

task :fetch_helm_certs => [:configure, :configure_secrets, :set_secrets] do
  sh "
    cd /project/live/${ENV}/k8s/kube-system/helm-initializer
    echo \"[helm-initializer] Pulling TF state...\"
    state=$(terragrunt state pull 2> /dev/null | jq -r \".modules[].resources | select(length > 0)\")
    for i in ca_cert helm_cert helm_key; do
      content=$(echo \"$state\" | jq -r \".[\\\"local_file.${i}\\\"].primary.attributes.content\")
      filename=$(echo \"$state\" | jq -r \".[\\\"local_file.${i}\\\"].primary.attributes.filename\")
      if [ \"$filename\" != \"\" ]; then
        echo \"[helm-initializer] Populating ${filename}...\"
        mkdir -p $(dirname \"${filename}\")
        echo \"${content}\" > \"${filename}\"
      else
        echo \"[helm-initializer] Could not find data for ${filename}. Skipping...\"
      fi
    done
    echo \"[helm-initializer] Here are the certs I fetched:\"
    find \"/project/live/${ENV}/secrets\" -type f | sort | xargs ls -l
  "
end

task :configure => [@gcp_creds_file, @app_default_creds_file, @kubectl_creds_file, :configure_current_project, :configure_extra_tf_vars] do
  # This is a wrapper configuration task.
  # It does nothing, but it has all dependencies that required for standard rake workflow.
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


# vim: et ts=2 sw=2:
