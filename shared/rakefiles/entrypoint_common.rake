desc "[ONLY ADMIN] Initialize GCP provider where all the projects will live"
task :apply_common_infra => [:set_vars, :configure_aws_restore] do
  # Steps to initialize GCP with a minimum set of resources to allow Terraform
  # create the rest of the infrastructure.
  # These steps are the same found in this tutorial:
  # https://cloud.google.com/community/tutorials/managing-gcp-projects-with-terraform
  sh "#{@exekube_cmd} rake apply_common_infra"
end

desc "[ONLY ADMIN] Fix the permissions for admin accounts in the organization"
task :fix_organization_permissions => [:set_vars] do
  # This task sets the permissions in the organization for creating the
  # projects and for setting the IAMs needed to manage such projects.
  #
  # Due to the needed permissions for setting such permissions, only an
  # administrator of the organization must run this task.
  sh "#{@exekube_cmd} rake fix_organization_permissions"
end
