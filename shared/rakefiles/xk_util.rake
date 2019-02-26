# This task rotates target args[:secret].
#
# New value for the secret can be set via env var TF_VAR_secret_name,
# otherwise new value will be generated automatically.
# Old secret value will be set to TF_VAR_secret_name_rotated until rotation is finished.
#
# Arbitrary command to execute after rotation can be set with :cmd argument.
task :rotate_secret, [:encryption_key, :secret, :cmd] => [:configure] do |taskname, args|
  if args[:encryption_key].nil? || args[:encryption_key].size == 0
    puts "  ERROR: Argument :encryption_key not present!"
    raise
  elsif args[:secret].nil? || args[:secret].size == 0
    puts "  ERROR: Argument :secret not present!"
    raise
  end

  @secrets = Secrets.collect_secrets()

  if @secrets[args[:encryption_key]].nil?
    puts "  ERROR: Encryption key '#{args[:encryption_key]}' does not exist!"
    raise
  elsif args[:secret] and ENV["TF_VAR_#{args[:secret]}"].nil?
    puts "  ERROR: Secret '#{args[:secret]}' does not exist!"
    raise
  end

  Secrets.set_secrets(@secrets)
  ENV["TF_VAR_#{args[:secret]}_rotated"] = ENV["TF_VAR_#{args[:secret]}"]
  ENV["TF_VAR_#{args[:secret]}"] = ""
  Secrets.set_secrets(@secrets, rotate_secrets = true)

  sh_filter "#{@exekube_cmd} #{args[:cmd]}" if args[:cmd]
end

# This task rotates KMS key and associated secrets file for target args[:encryption_key].
task :rotate_secrets_key, [:encryption_key] => [:configure] do |taskname, args|
  if args[:encryption_key].nil? || args[:encryption_key].size == 0
    puts "  ERROR: Argument :encryption_key not present!"
    raise
  end

  @secrets = Secrets.collect_secrets()

  if @secrets[args[:encryption_key]].nil?
    puts "  ERROR: Encryption key '#{args[:encryption_key]}' does not exist!"
    raise
  end

  Secrets.set_secrets(@secrets)
  new_version_id = Secrets.create_key_version(args[:encryption_key])
  Secrets.set_secrets(@secrets, rotate_secrets = true)
  Secrets.disable_non_primary_key_versions(args[:encryption_key], new_version_id)
end

# This task destroy all keys except current one for projectowner's SA.
# It does nothing in case local SA credentials not present.
task :destroy_sa_keys => [@gcp_creds_file, :configure_extra_tf_vars] do
  sh "
    if [ \"$TF_VAR_serviceaccount_key\" != \"\" ] && [ -f $TF_VAR_serviceaccount_key ]; then \
      existing_keys=$(gcloud iam service-accounts keys list \
        --iam-account projectowner@\"$TF_VAR_project_id\".iam.gserviceaccount.com \
        --managed-by user | grep -oE \"^[a-z0-9]+\"); \
      current_key=$(cat $TF_VAR_serviceaccount_key 2>/dev/null | jq -r '.private_key_id'); \
      for key in $existing_keys; do \
        if [ \"$key\" != \"$current_key\" ]; then \
          yes | gcloud iam service-accounts keys delete \
            --iam-account projectowner@\"$TF_VAR_project_id\".iam.gserviceaccount.com $key; \
        fi \
      done
    fi
  "
end

task :display_cluster_state => [:configure] do
  puts
  puts "**************"
  puts "Cluster state:"
  puts "**************"
  puts
  for cmd in [
    "kubectl -n gpii get all -o wide",
    "kubectl -n gpii get pv -o wide",
    "kubectl -n gpii get pvc -o wide",
    "kubectl -n gpii get events -o wide",
    "kubectl -n locust get all -o wide",
    "kubectl -n locust get events -o wide",
  ]
    sh "timeout -t 30 #{cmd}"
  end
end

# This task attaches the owner role to the current user
task :grant_owner_role => [@gcp_creds_file, :configure_extra_tf_vars] do
  sh "
    gcloud projects add-iam-policy-binding \"$TF_VAR_project_id\" --member user:\"$TF_VAR_auth_user_email\" --role roles/owner
  "
end

# This task removes the owner role to the current user
task :revoke_owner_role => [@gcp_creds_file, :configure_extra_tf_vars] do
  sh "
    gcloud projects remove-iam-policy-binding \"$TF_VAR_project_id\" --member user:\"$TF_VAR_auth_user_email\" --role roles/owner
  "
end

# vim: et ts=2 sw=2:
