desc "[ONLY ADMIN] Initialize GCP provider where all the projects will live"
task :infra_init => [:set_vars] do
  # Steps to initialize GCP with a minimum set of resources to allow Terraform
  # create the rest of the infrastructure.
  # These steps are the same found in this tutorial:
  # https://cloud.google.com/community/tutorials/managing-gcp-projects-with-terraform
  #
  # Due to the needed permissions for creating the following resources, only an
  # administrator of the organization can run this task.

  if @project_type != "common"
    puts "infra_init must run inside common/live/[prd|stg]"
    exit
  end
  @exekube_cmd_with_volume = @exekube_cmd.sub(
    " run ",
    " run --volume #{ENV["HOME"]}/.aws:/aws-backup ",
  )
  sh "#{@exekube_cmd_with_volume} sh -c '\
    cp -av /aws-backup/* /root/.aws/ \
  '"
  #sh "#{@exekube_cmd} rake infra_init"
end
