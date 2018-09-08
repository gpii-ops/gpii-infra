require "rake/clean"

require_relative "./secrets.rb"
require_relative "./sh_filter.rb"

@exekube_cmd = "/usr/local/bin/xk"

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
task :configure_serviceaccount => [@gcp_creds_file, :configure_current_project] do
  # TODO: This command is duplicated from exekube's gcp-project-init (and
  # hardcodes 'projectowner' instead of $SA_NAME which is only defined in
  # gcp-project-init). If gcp-project-init becomes idempotent (GPII-2989,
  # https://github.com/exekube/exekube/issues/92), or if this 'keys create'
  # step moves somewhere else in exekube, call this command from that place
  # instead.
  sh "
    [ -f $TF_VAR_serviceaccount_key ] || \
    gcloud iam service-accounts keys create $TF_VAR_serviceaccount_key \
      --iam-account projectowner@$TF_VAR_project_id.iam.gserviceaccount.com
  "
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

# This task is being called from entrypoint.rake and runs inside exekube container.
# It applies secret-mgmt, sets secrets, and then executes arbitrary command from args[:cmd].
# You should not invoke this task directly!
task :xk, [:cmd, :skip_secret_mgmt] => [@serviceaccount_key_file, @kubectl_creds_file] do |taskname, args|
  @secrets = Secrets.collect_secrets()

  sh "#{@exekube_cmd} up live/#{@env}/secret-mgmt" unless args[:skip_secret_mgmt]

  Secrets.set_secrets(@secrets)

  sh_filter "#{@exekube_cmd} #{args[:cmd]}" if args[:cmd]
end

task :refresh_common_infra, [:project_type] => [@gcp_creds_file] do | taskname, args|

  next if args[:project_type] == "common"

  # The common infrastructure might create the DNS resources, in order to avoid
  # conflicts at the creation resources we need to import the already created
  # DNS zone.

  output = `#{@exekube_cmd} sh -c "\
    terragrunt output -json dns_zones \
    --terragrunt-working-dir /project/live/#{@env}/infra/network 2>/dev/null
    "`
  begin
    id_found = !!JSON.parse(output)
  rescue JSON::ParserError
    id_found = false
  end

  if not id_found then
    # The DNS zone is not in the TF state file, we need to add it
    puts "DNS zone #{ENV["TF_VAR_domain_name"].tr('.','-')} not found in TF state, importing..."
    sh "#{@exekube_cmd} sh -c '\
      terragrunt import module.gke_network.google_dns_managed_zone.dns_zones #{ENV["TF_VAR_domain_name"].tr('.','-')} \
      --terragrunt-working-dir /project/live/#{@env}/infra/network \
      '"
  else
    # The DNS zone is in the TF state file, we will refresh it just in case
    puts "DNS zone #{ENV["TF_VAR_domain_name"].tr('.','-')} found in TF state, refreshing..."
    sh "#{@exekube_cmd} sh -c '\
      terragrunt refresh \
      --terragrunt-working-dir /project/live/#{@env}/infra/network \
      '"
  end
end

task :apply_common_infra => [@gcp_creds_file] do
  # Steps to initialize GCP with a minimum set of resources to allow Terraform
  # create the rest of the infrastructure.
  # These steps are the same found in this tutorial:
  # https://cloud.google.com/community/tutorials/managing-gcp-projects-with-terraform
  #
  # Due to the needed permissions for creating the following resources, only an
  # administrator of the organization can run this task.

  output = `#{@exekube_cmd} gcloud projects list --format='json' --filter='name:#{ENV["TF_VAR_project_id"]}'`
  hash = JSON.parse(output)
  if hash.empty?
    puts "#{ENV["TF_VAR_project_id"]} not found, I'll create a new one"
    sh "
      #{@exekube_cmd} gcloud projects create #{ENV["TF_VAR_project_id"]} \
      --organization #{ENV["ORGANIZATION_ID"]} \
      --set-as-default"
  else
    Rake::Task[:configure_current_project].invoke
  end

  sh "
    #{@exekube_cmd} gcloud beta billing projects link #{ENV["TF_VAR_project_id"]} \
    --billing-account #{ENV["BILLING_ID"]}"

  output = `#{@exekube_cmd} gcloud iam service-accounts list --format='json' \
            --filter='email:projectowner@#{ENV["TF_VAR_project_id"]}.iam.gserviceaccount.com'`
  hash = JSON.parse(output)
  if hash.empty?
    sh "#{@exekube_cmd} gcloud iam service-accounts create projectowner \
        --display-name 'CI account'"
  end

  Rake::Task[:configure_serviceaccount].invoke

  ["roles/viewer", "roles/storage.admin", "roles/dns.admin"].each do |role|

  sh "#{@exekube_cmd} gcloud projects add-iam-policy-binding #{ENV["TF_VAR_project_id"]} \
            --member serviceAccount:projectowner@#{ENV["TF_VAR_project_id"]}.iam.gserviceaccount.com \
            --role #{role}"
  end

  output = `#{@exekube_cmd} gcloud services list --format='json'`
  hash = JSON.parse(output)

  ["cloudresourcemanager.googleapis.com",
   "cloudbilling.googleapis.com",
   "iam.googleapis.com",
   "dns.googleapis.com",
   "compute.googleapis.com"].each do |service|
     sh "#{@exekube_cmd} gcloud services enable #{service}" unless hash.any? { |s| s['serviceName'] == service }
  end

  ["roles/resourcemanager.projectCreator", "roles/billing.user"].each do |role|
    sh "#{@exekube_cmd} gcloud organizations add-iam-policy-binding #{ENV["ORGANIZATION_ID"]} \
      --member serviceAccount:projectowner@#{ENV["TF_VAR_project_id"]}.iam.gserviceaccount.com \
      --role #{role}"
  end

  `#{@exekube_cmd} gsutil ls gs://#{ENV["TF_VAR_project_id"]}-tfstate`
  if $?.exitstatus != 0
    sh "#{@exekube_cmd} gsutil mb gs://#{ENV["TF_VAR_project_id"]}-tfstate"
  end

  sh "#{@exekube_cmd} gsutil versioning set on gs://#{ENV["TF_VAR_project_id"]}-tfstate"
end

# vim: et ts=2 sw=2:
