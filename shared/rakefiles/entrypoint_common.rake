desc "[ONLY ADMIN] Initialize GCP provider where all the projects will live"
task :apply_common_infra => [:set_vars] do
  # Steps to initialize GCP with a minimum set of resources to allow Terraform
  # create the rest of the infrastructure.
  # These steps are the same found in this tutorial:
  # https://cloud.google.com/community/tutorials/managing-gcp-projects-with-terraform
  sh "#{@exekube_cmd} rake apply_common_infra"
end

desc "[ONLY ADMIN] Set required permissions for the accounts in the current organization"
task :set_org_perms => [:set_vars] do
  # This task sets the permissions in the organization for creating the
  # projects and for setting the IAMs needed to manage such projects.
  #
  # Due to the needed permissions for setting such permissions, only an
  # administrator of the organization must run this task.
  sh "#{@exekube_cmd} rake set_org_perms"
end

desc "[ONLY ADMIN] Set required permissions for the accounts in the organization that owns billing account"
task :set_billing_org_perms => [:set_vars] do
  # We need to grant Billing User role in the organization that owns
  # Billing Account to the projectowner SA of current organization, otherwise it will
  # fail to create new projects.
  #
  # WARNING: You need to run this code authenticated under your main (member of cloud-admin group) account.
  #          It will not work in CI or if you are using projectowner SA.
  #
  # Go to the https://console.cloud.google.com/billing/ to see the permissions granted.
  sh "#{@exekube_cmd} rake set_billing_org_perms"
end

desc "[ONLY ADMIN] Display added or removed assets in target projects (comma separated) for the compare duration in seconds"
task :display_scc_assets_changed, [:projects, :compare_duration] => [:set_vars] do |taskname, args|
  sh "#{@exekube_cmd} rake display_scc_assets_changed['#{args[:projects]}','#{args[:compare_duration]}']"
end

desc "[ONLY ADMIN] Display SCC findings"
task :display_scc_findings => [:set_vars] do
  sh "#{@exekube_cmd} rake display_scc_findings"
end
