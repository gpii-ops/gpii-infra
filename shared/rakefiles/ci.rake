task :set_vars_ci => [:set_vars] do
  @secrets_backup_volume = "#{ENV["TF_VAR_project_id"]}-#{ENV["USER"]}-secrets-backup"
  # --volume must come after 'docker-compose run', before service name.
  @exekube_cmd_with_backups = @exekube_cmd.sub(
    " run ",
    " run --volume #{@secrets_backup_volume}:/secrets-backup ",
  )
  @exekube_cmd_with_aws_volume = @exekube_cmd.sub(
    " run ",
    " run --volume #{ENV["HOME"]}/.aws:/aws-backup ",
  )
  # This duplicates information from xk_config.rake,
  # see corresponding :configure_serviceaccount task for more info.
  @serviceaccount_key_file = "/project/live/#{@env}/secrets/kube-system/owner.json"
  @serviceaccount_key_file_in_backups = @serviceaccount_key_file.sub(
    "/project",
    "/secrets-backup",
  )
end

desc "[CI ONLY] Create and download credentials for projectowner service account"
task :configure_serviceaccount => [:set_vars] do
  sh "#{@exekube_cmd} rake configure_serviceaccount"
end

desc "[CI ONLY] Restore GCP credentials from local backup on CI worker"
task :configure_serviceaccount_ci_restore => [:set_vars_ci] do
  # The automated CI process cannot (and does not want to) authenticate in the
  # normal, interactive way. Instead, we will fetch previously downloaded
  # credentials, copy them to the expected place, and activate them for later
  # use by `gcloud` commands.
  #
  # Another way to think of it: this task uses an alternate strategy to create
  # service account key file.
  sh "#{@exekube_cmd_with_backups} sh -c '\
    mkdir -p $(dirname #{@serviceaccount_key_file}) && \
    cp -av #{@serviceaccount_key_file_in_backups} #{@serviceaccount_key_file} \
  '"
  sh "#{@exekube_cmd} sh -c '\
    gcloud auth activate-service-account \
      --key-file #{@serviceaccount_key_file} \
      --project $TF_VAR_project_id \
  '"
end

task :configure_aws_restore => [:set_vars_ci] do
  # Puts the AWS credentials a Docker volume to be consumed by the apps inside the container
  sh "#{@exekube_cmd_with_aws_volume} sh -c '\
    cp -av /aws-backup/* /root/.aws/ \
  '"
end

desc "[CI ONLY] Save GCP credentials to local backup on CI worker"
task :configure_serviceaccount_ci_save => [:set_vars_ci] do
  sh "#{@exekube_cmd_with_backups} sh -c '\
    mkdir -p $(dirname #{@serviceaccount_key_file_in_backups}) && \
    cp -av #{@serviceaccount_key_file} #{@serviceaccount_key_file_in_backups} \
  '"
end

desc "[CI ONLY] Clobber local backup on CI worker"
task :configure_serviceaccount_ci_clobber => [:set_vars_ci]  do
  sh "docker volume rm -f -- #{@secrets_backup_volume}"
end

# vim: et ts=2 sw=2:
