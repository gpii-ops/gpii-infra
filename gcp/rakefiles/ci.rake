task :set_vars_ci => [:set_vars] do
  # --volume must come after 'docker-compose run', before service name.
  @exekube_cmd_with_backups = @exekube_cmd.sub(
    " run ",
    " run --volume #{ENV["TF_VAR_project_id"]}-#{ENV["USER"]}-secrets-backup:/secrets-backup ",
  )
  # This duplicates information in docker-compose.yaml,
  # TF_VAR_serviceaccount_key.
  @serviceaccount_key_file = "/project/live/#{@env}/secrets/kube-system/owner.json"
  @serviceaccount_key_file_in_backups = @serviceaccount_key_file.sub(
    "/project",
    "/secrets-backup",
  )
end

desc "[EXPERT] Restore GCP credentials from local backup on CI worker"
task :configure_serviceaccount_ci_restore => [:set_vars_ci] do
  # The automated CI process cannot (and does not want to) authenticate in the
  # normal, interactive way. Instead, we will fetch previously downloaded
  # credentials, copy them to the expected place, and activate them for later
  # use by `gcloud` commands.
  #
  # Another way to think of it: this task uses an alternate strategy to create
  # $TF_VAR_serviceaccount_key.
  sh "#{@exekube_cmd_with_backups} sh -c '\
    mkdir -p $(dirname $TF_VAR_serviceaccount_key) && \
    cp -av #{@serviceaccount_key_file_in_backups} $TF_VAR_serviceaccount_key \
  '"
  # The 'touch' is to keep serviceaccount_key_file newer than gcloud's
  # credentials.db. Otherwise, serviceaccount_key_file is always generated on
  # the next run since it is always older than credentials.db.
  sh "#{@exekube_cmd} sh -c '\
    gcloud auth activate-service-account \
      --key-file $TF_VAR_serviceaccount_key \
      --project $TF_VAR_project_id && \
    touch $TF_VAR_serviceaccount_key \
  '"
end

desc "[EXPERT] Save GCP credentials to local backup on CI worker"
task :configure_serviceaccount_ci_save => [:set_vars_ci] do
  sh "#{@exekube_cmd_with_backups} sh -c '\
    mkdir -p $(dirname #{@serviceaccount_key_file_in_backups}) && \
    cp -av $TF_VAR_serviceaccount_key #{@serviceaccount_key_file_in_backups} \
  '"
end

# vim: et ts=2 sw=2:
