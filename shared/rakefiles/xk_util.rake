org_admin_roles = [
  "roles/iam.serviceAccountAdmin",
  "roles/securitycenter.admin",
]

# This task rotates target args[:secret].
#
# New value for the secret can be set via env var TF_VAR_secret_name,
# otherwise new value will be generated automatically.
# Old secret value will be set to TF_VAR_secret_name_rotated until rotation is finished.
#
# Arbitrary command to execute after rotation can be set with :cmd argument.
task :rotate_secret, [:encryption_key, :secret, :cmd] => [:configure, :configure_secrets] do |taskname, args|
  if args[:encryption_key].nil? || args[:encryption_key].size == 0
    puts "  ERROR: Argument :encryption_key not present!"
    raise
  elsif args[:secret].nil? || args[:secret].size == 0
    puts "  ERROR: Argument :secret not present!"
    raise
  end

  if @secrets.collected_secrets[args[:encryption_key]].nil?
    puts "  ERROR: Encryption key '#{args[:encryption_key]}' does not exist!"
    raise
  elsif args[:secret] and ENV["TF_VAR_#{args[:secret]}"].nil?
    puts "  ERROR: Secret '#{args[:secret]}' does not exist!"
    raise
  end

  Rake::Task["set_secrets"].invoke
  ENV["TF_VAR_#{args[:secret]}_rotated"] = ENV["TF_VAR_#{args[:secret]}"]
  ENV["TF_VAR_#{args[:secret]}"] = ""
  rotate_secrets = true
  @secrets.set_secrets(rotate_secrets)

  sh_filter "#{@exekube_cmd} #{args[:cmd]}" if args[:cmd]
end

# This task rotates KMS key and associated secrets file for target args[:encryption_key].
task :rotate_secrets_key, [:encryption_key] => [:configure, :configure_secrets] do |taskname, args|
  if args[:encryption_key].nil? || args[:encryption_key].size == 0
    puts "  ERROR: Argument :encryption_key not present!"
    raise
  end

  if @secrets.collected_secrets[args[:encryption_key]].nil?
    puts "  ERROR: Encryption key '#{args[:encryption_key]}' does not exist!"
    raise
  end

  Rake::Task["set_secrets"].invoke
  new_version_id = @secrets.create_key_version(args[:encryption_key])
  rotate_secrets = true
  @secrets.set_secrets(rotate_secrets)
  @secrets.disable_non_primary_key_versions(args[:encryption_key], new_version_id)
end

# This is an EXPERIMENTAL helper for moving between regions, but it is not very smart and it
# is strongly coupled with the gcp-secret-mgmt module (e.g. if resource names
# change there, they will also need to change here).
task :import_keyring => [:configure, :configure_secrets] do
  # Remove and then import the Keyring
  sh "#{@exekube_cmd} sh -c ' \
    terragrunt state rm module.gcp-secret-mgmt.google_kms_key_ring.key_ring \
      --terragrunt-working-dir /project/live/#{@env}/secret-mgmt &&\
    terragrunt import module.gcp-secret-mgmt.google_kms_key_ring.key_ring \
      projects/#{ENV["TF_VAR_project_id"]}/locations/#{ENV["TF_VAR_infra_region"]}/keyRings/#{ENV["TF_VAR_keyring_name"]} \
      --terragrunt-working-dir /project/live/#{@env}/secret-mgmt \
  '"

  # Remove and then import the Keys
  secrets_config = @secrets.load_secrets_config()
  secrets_config["encryption_keys"].each_with_index do |key_name, index|
    sh "#{@exekube_cmd} sh -c ' \
      terragrunt state rm module.gcp-secret-mgmt.google_kms_crypto_key.encryption_keys[#{index}] \
        --terragrunt-working-dir /project/live/#{@env}/secret-mgmt &&\
      terragrunt import module.gcp-secret-mgmt.google_kms_crypto_key.encryption_keys[#{index}] \
        projects/#{ENV["TF_VAR_project_id"]}/locations/#{ENV["TF_VAR_infra_region"]}/keyRings/#{ENV["TF_VAR_keyring_name"]}/cryptoKeys/#{key_name} \
        --terragrunt-working-dir /project/live/#{@env}/secret-mgmt \
    '"
  end
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

task :display_cluster_state => [:configure, :configure_secrets, :set_secrets] do
  puts
  puts "**************"
  puts "Cluster state:"
  puts "**************"
  puts
  cmds = [
    "kubectl -n gpii get all -o wide",
    "kubectl -n gpii get pv -o wide",
    "kubectl -n gpii get pvc -o wide",
    "kubectl -n gpii get events -o wide",
    "kubectl -n locust get all -o wide",
    "kubectl -n locust get events -o wide",
    # The 'terraform' disks are root partitions. Filter those out to reduce
    # some clutter.
    "gcloud compute disks list --filter 'NOT name:gke-k8s-cluster-terraform' --format json",
  ]
  dev_cmds = [
    # Only run this in dev because a) we expect to see weird behavior in
    # ephemeral clusters, not long-lived clusters and b) 'kubectl exec'
    # generates an alert, which is not ok in stg/prd.
    "kubectl exec --namespace gpii couchdb-couchdb-0 -c couchdb -- curl -s http://$TF_VAR_secret_couchdb_admin_username:$TF_VAR_secret_couchdb_admin_password@127.0.0.1:5984/_membership | jq .",
    "kubectl exec --namespace gpii couchdb-couchdb-1 -c couchdb -- curl -s http://$TF_VAR_secret_couchdb_admin_username:$TF_VAR_secret_couchdb_admin_password@127.0.0.1:5984/_membership | jq .",
  ]
  if @env == "dev"
    cmds.concat(dev_cmds)
  end
  for cmd in cmds
    sh "timeout -t 30 #{cmd}"
  end
end

task :display_universal_image_info => [:configure] do
  sh "#{@exekube_cmd} sh -c ' \
    UNIVERSAL_CI_URL=\"https://ci.gpii.net\";
    UNIVERSAL_REPO=\"https://github.com/gpii/universal\";
    RELEASE_JOB_URL=\"$UNIVERSAL_CI_URL/job/docker-gpii-universal-master-release\";
    UPSTREAM_JOB_URL=\"$UNIVERSAL_CI_URL/job/docker-gpii-universal-master\";
    LOOKUP_BUILDS=\"20\";

    PREFERENCES_IMAGE_SHA=$(kubectl -n gpii get deployment preferences -o json 2> /dev/null | jq -r \".spec.template.spec.containers[0].image\" | grep -o \"sha256:.*\");
    if [ \"$?\" != \"0\" ]; then
      echo
      echo \"Unable to retrieve data from K8s cluster!\";
      echo \"Try running \\\`rake display_cluster_state\\\` for debug info.\";
      echo
      exit 1;
    fi

    echo
    echo \"Preferences image SHA:\";
    echo \"$PREFERENCES_IMAGE_SHA\";
    RELEASE_BUILD=$(curl -f \"$RELEASE_JOB_URL/lastBuild/api/json\" 2> /dev/null | jq -r \".id\");
    RELEASE_BUILD_LIMIT=$((RELEASE_BUILD - LOOKUP_BUILDS));
    while [ \"$RELEASE_BUILD\" != \"\" ] && [ \"$RELEASE_BUILD\" -gt \"$RELEASE_BUILD_LIMIT\" ]; do
      SHA_FOUND=$(curl -f \"$RELEASE_JOB_URL/$RELEASE_BUILD/consoleText\" 2> /dev/null | grep -so \"$PREFERENCES_IMAGE_SHA\" || true);
      if [ \"$SHA_FOUND\" == \"$PREFERENCES_IMAGE_SHA\" ]; then
        UPSTREAM_JOB_NUMBER=$(curl -f \"$RELEASE_JOB_URL/$RELEASE_BUILD/api/json\" 2> /dev/null | jq -r \".actions[] | select (.causes[0].upstreamBuild != null) | .causes[0].upstreamBuild\");
        GITHUB_LINK=\"$UNIVERSAL_REPO/commit/$(curl -f \"$UPSTREAM_JOB_URL/$UPSTREAM_JOB_NUMBER/api/json\" 2> /dev/null | jq -r \".actions[] | select (.lastBuiltRevision.SHA1 != null) | .lastBuiltRevision.SHA1\")\";
        echo
        echo \"Release job that built the image:\";
        echo \"$RELEASE_JOB_URL/$RELEASE_BUILD\";
        echo
        echo \"Upstream job:\";
        echo \"$UPSTREAM_JOB_URL/$UPSTREAM_JOB_NUMBER\";
        RELEASE_BUILD=1;
      fi
      RELEASE_BUILD=$((RELEASE_BUILD - 1));
    done

    if [ \"$GITHUB_LINK\" == \"\" ]; then
      echo
      echo \"Unable to get CI data for target image SHA in last $LOOKUP_BUILDS builds!\";
      echo
      exit 1;
    fi

    echo
    echo \"Commit to gpii/universal that triggered image build:\";
    echo \"$GITHUB_LINK\";
    echo
  '", verbose: false
end

# This task grants the owner role in the current project to the current user
task :grant_project_admin => [@gcp_creds_file, :configure_extra_tf_vars] do
  sh "
    gcloud projects add-iam-policy-binding \"$TF_VAR_project_id\" \
      --member user:\"$TF_VAR_auth_user_email\" \
      --role roles/owner
  "
end

# This task revokes the owner role in the current project from the current user
task :revoke_project_admin => [@gcp_creds_file, :configure_extra_tf_vars] do
  sh "
    gcloud projects remove-iam-policy-binding \"$TF_VAR_project_id\" \
      --member user:\"$TF_VAR_auth_user_email\" \
      --role roles/owner
  "
end

# This task grants organization roles declared in org_admin_roles to the current user
task :grant_org_admin => [@gcp_creds_file, :configure_extra_tf_vars] do
  org_admin_roles.each do |role|
    sh "#{@exekube_cmd} gcloud organizations add-iam-policy-binding #{ENV["ORGANIZATION_ID"]} \
      --member user:\"$TF_VAR_auth_user_email\" \
      --role #{role}"
  end
end

# This task revokes organization roles declared in org_admin_roles from the current user
task :revoke_org_admin => [@gcp_creds_file, :configure_extra_tf_vars] do
  org_admin_roles.each do |role|
    sh "#{@exekube_cmd} gcloud organizations remove-iam-policy-binding #{ENV["ORGANIZATION_ID"]} \
      --member user:\"$TF_VAR_auth_user_email\" \
      --role #{role}"
  end
end

# This task restores a list of images in snapshots. All the snapshots are stored
# in the actual region of the project in the zone A.
task :restore_snapshot_from_image_file, [:snapshot_files] => [@gcp_creds_file, :configure_extra_tf_vars] do |taskname, args|

  snapshot_files = args[:snapshot_files].split ' '
  snapshot_files.each do |snapshot_file|
    sh "#{@exekube_cmd} sh -c ' \
      gsutil ls #{snapshot_file}
    '", verbose: false
  end

  [ "roles/iam.serviceAccountUser", "roles/compute.admin" ].each do |role|
    sh "gcloud projects add-iam-policy-binding \"#{ENV["TF_VAR_project_id"]}\" \
      --member serviceAccount:\"$(gcloud projects list --filter=\"#{ENV["TF_VAR_project_id"]}\" --format=\"value(PROJECT_NUMBER)\")-compute@developer.gserviceaccount.com\" \
      --role '#{role}'"
  end

  snapshot_files.each do |snapshot_file|
    snapshot_name = snapshot_file[/pv-database-storage-couchdb-couchdb-\d-\d+-\d+/, 0]
    sh "#{@exekube_cmd} sh -c ' \
    gcloud compute images create image-disk-#{snapshot_name} --source-uri=#{snapshot_file}
    gcloud compute disks create disk-#{snapshot_name} --zone=#{ENV["TF_VAR_infra_region"]}-a --image=image-disk-#{snapshot_name}
    gcloud compute disks snapshot disk-#{snapshot_name} --zone=#{ENV["TF_VAR_infra_region"]}-a --snapshot-names external-#{snapshot_name}
    gcloud compute disks delete disk-#{snapshot_name}
    '", verbose: false
  end

end
# vim: et ts=2 sw=2:
