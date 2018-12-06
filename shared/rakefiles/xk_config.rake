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
task :configure_serviceaccount, [:use_projectowner_sa] => [@gcp_creds_file, :configure_current_project] do |taskname, args|
  # Setting authenticated user's email into env variable, so it can be
  # accessible in modules: https://issues.gpii.net/browse/GPII-3516
  ENV['TF_VAR_auth_user_email'] = %x{
    gcloud auth list --filter='account!~gserviceaccount.com' --format json |  jq -r '.[].account'
  }.chomp!
  # TODO: This command is duplicated from exekube's gcp-project-init (and
  # hardcodes 'projectowner' instead of $SA_NAME which is only defined in
  # gcp-project-init). If gcp-project-init becomes idempotent (GPII-2989,
  # https://github.com/exekube/exekube/issues/92), or if this 'keys create'
  # step moves somewhere else in exekube, call this command from that place
  # instead.
  if args[:use_projectowner_sa]
    sh "
      [ -f $TF_VAR_serviceaccount_key ] || \
      gcloud iam service-accounts keys create $TF_VAR_serviceaccount_key \
        --iam-account projectowner@$TF_VAR_project_id.iam.gserviceaccount.com
    "
  else
    # This block of code creates new service account for authenticated user
    # and assigns all 'projectowner' roles to it.
    # Having separate service account per authenticated user is important for
    # audit purposes: https://issues.gpii.net/browse/GPII-3325
    unless File.file?(@serviceaccount_key_file)
      sh "
        sa_name=$(echo \\\"#{ENV['TF_VAR_auth_user_email']}\\\" | jq -r '. | sub(\"@\"; \"-at-\") | sub(\"\\\\.\"; \"-\") | .[0:30]');
        sa_email=$(gcloud iam service-accounts list \
          --filter=\"email:$sa_name@$TF_VAR_project_id.iam.gserviceaccount.com\" \
          --format json | jq -r .[].email);
        projectowner_roles=$(gcloud projects get-iam-policy $TF_VAR_project_id \
          --flatten=\"bindings[].members\" --filter \"bindings.members:projectowner@$TF_VAR_project_id.iam.gserviceaccount.com\" \
          --format json | jq -r '.[].bindings.role');
        if [ \"$sa_email\" == \"\" ]; then
          gcloud iam service-accounts create $sa_name --display-name \"Service account for #{ENV['TF_VAR_auth_user_email']}\"
        fi
        for role in $projectowner_roles; do
          echo \"Adding $role role to $sa_name@$TF_VAR_project_id.iam.gserviceaccount.com...\"
          gcloud projects add-iam-policy-binding $TF_VAR_project_id  \
            --member=\"serviceAccount:$sa_name@$TF_VAR_project_id.iam.gserviceaccount.com\" \
            --role=\"$role\" > /dev/null
        done
        gcloud iam service-accounts keys create $TF_VAR_serviceaccount_key \
          --iam-account $sa_name@$TF_VAR_project_id.iam.gserviceaccount.com;
      "
    end
  end
end

# This task deletes service account for authenticated user and removes stored credentials
task :destroy_serviceaccount => [@gcp_creds_file, :configure_current_project] do
  sh "
    sa_email=$(gcloud auth list --filter='account!~gserviceaccount.com' --format json |  jq -r '.[].account');
    sa_name=$(echo \\\"$sa_email\\\" | jq -r '. | sub(\"@\"; \"-at-\") | sub(\"\\\\.\"; \"-\") | .[0:30]');
    if [ \"$sa_name\" != \"\" ]; then
      gcloud config set account $sa_email;
      sa_roles=$(gcloud projects get-iam-policy $TF_VAR_project_id \
        --flatten=\"bindings[].members\" --filter \"bindings.members:$sa_name@$TF_VAR_project_id.iam.gserviceaccount.com\" \
        --format json | jq -r '.[].bindings.role');
      for role in $sa_roles; do
        echo \"Removing $role role from $sa_name@$TF_VAR_project_id.iam.gserviceaccount.com...\"
        gcloud projects remove-iam-policy-binding $TF_VAR_project_id  \
          --member=\"serviceAccount:$sa_name@$TF_VAR_project_id.iam.gserviceaccount.com\" \
          --role=\"$role\" > /dev/null
      done
      if [ \"$sa_roles\" != \"\" ]; then
        yes | gcloud iam service-accounts delete $sa_name@$TF_VAR_project_id.iam.gserviceaccount.com;
      fi
    fi
  "

  File.delete(@serviceaccount_key_file) if File.exist?(@serviceaccount_key_file)
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
