desc "[ONLY ADMIN] Initialize GCP provider where all the projects will live"
task :apply_common_infra => [:set_vars, :configure_aws_restore] do
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

# We need Google to create the Container Registry for us (see
# common/modules/gcp-container-registry/main.tf). This task pushes an image to
# the Registry, which creates the Registry if it does not exist (or does
# basically nothing if it already exists).
task :init_registry => [:set_vars] do
  # I've chosen the current exekube base image (alpine:3.8) because it is small
  # and because it will end up in the Registry anyway. Note that this
  # duplicates information in exekube/dockerfiles, i.e. there is coupling
  # without cohesion.
  image = "alpine:3.8"
  registry_url_base = "gcr.io"
  registry_url = "#{registry_url_base}/#{ENV["TF_VAR_project_id"]}"

  # Pull the image to localhost
  sh "docker pull #{image}"

  # Tag the local image with our Registry
  sh "docker tag #{image} #{registry_url}/#{image}"

  # Authenticate with gcloud if we haven't already (the task that does this
  # must run inside the exekube container, so we can't include it as a
  # dependency to this task).
  sh "#{@exekube_cmd} rake configure_login"

  # Get an auth token using our gcloud credentials
  token = %x{
    #{@exekube_cmd} gcloud auth print-access-token
  }.chomp

  # Load the auth token into Docker
  # (Use an env var to avoid echoing the token to stdout / the CI logs.)
  ENV["RAKE_INIT_REGISTRY_TOKEN"] = token
  sh "echo \"$RAKE_INIT_REGISTRY_TOKEN\" | docker login -u oauth2accesstoken --password-stdin https://#{registry_url_base}"

  # Push the local image to our Registry
  sh "docker push #{registry_url}/#{image}"

  # Clean up
  sh "docker rmi #{registry_url}/#{image}" # || true"
  # We won't remove #{image} in case it existed previously. This is a small leak.
end
