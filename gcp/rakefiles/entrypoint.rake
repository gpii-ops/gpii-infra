require "rake/clean"
require "json"

require_relative "./vars.rb"
require_relative "./secrets.rb"
require_relative "./sh_filter.rb"

if @env.nil?
  puts "  ERROR: @env must be set!"
  puts "  This is a problem in rake code."
  puts "  Set @env before importing this rakefile."
  raise ArgumentError, "@env must be set"
end
if @project_type.nil?
  puts "  ERROR: @project_type must be set!"
  puts "  This is a problem in rake code."
  puts "  Set @project_type before importing this rakefile."
  raise ArgumentError, "@project_type must be set"
end

@exekube_cmd = "docker-compose run --rm --service-ports xk"

['secrets', 'values'].each do |dir|
  Dir.mkdir(dir) unless File.exists?(dir)
end

desc "Create cluster and deploy GPII components to it"
task :default => :deploy

task :set_vars do
  Vars.set_vars(@env, @project_type)
  @secrets = Secrets.set_secrets()
  json_sa_key_file = File.read(@serviceaccount_key_file)
  data_sa_key_file = JSON.parse(json_sa_key_file)
  unless data_sa_key_file["project_id"] == ENV["TF_VAR_project_id"]
    puts "Seems that the serviceAccount configured (#{data_sa_key_file["project_id"]}) doesn't match with the env where you're #{ENV["TF_VAR_project_id"]}"
    puts "Please rerun project_init task to set the correct credentials or change the current active directory"
    exit
  end
end

@dot_config_path = "../../.config/#{@env}"
CLOBBER << @dot_config_path

@gcp_creds_file = "#{@dot_config_path}/gcloud/credentials.db"
desc "[ADVANCED] Authenticate and generate GCP credentials (gcloud auth login)"
task :auth => [:set_vars, @gcp_creds_file]
rule @gcp_creds_file do
  sh "#{@exekube_cmd} gcloud auth login"
end

@kubectl_creds_file = "#{@dot_config_path}/kube/config"
desc "[ADVANCED] Fetch kubectl credentials (gcloud auth login)"
task :configure_kubectl => [:set_vars, @gcp_creds_file, @kubectl_creds_file]
rule @kubectl_creds_file do
  # This duplicates information in terraform code, 'k8s-cluster'
  cluster_name = 'k8s-cluster'
  # This duplicates information in terraform code, 'zone'. Could be a variable with some plumbing.
  zone = 'us-central1-a'
  sh "
    if [[ $(#{@exekube_cmd} gcloud container clusters list --filter #{cluster_name} --zone #{zone} --project #{ENV["TF_VAR_project_id"]}) ]] ; \
    then \
      #{@exekube_cmd} gcloud container clusters get-credentials #{cluster_name} --zone #{zone} --project #{ENV["TF_VAR_project_id"]}
    fi"
end

desc "[ONLY ADMIN] Initialize GCP provider where all the projects will live"
task :infra_init => [:set_vars, @gcp_creds_file] do
  # Steps to initialize GCP with a minimum set of resources to allow Terraform
  # create the rest of the infrastructure.
  # These steps are the same found in this tutorial:
  # https://cloud.google.com/community/tutorials/managing-gcp-projects-with-terraform
  #
  # Due to the needed permissions for creating the following resources, only an
  # administrator of the organization can run this task.

  if @project_type != "common" or @env != "prd"
    puts "infra_init must run inside common/live/prd"
    exit
  end
  output = `#{@exekube_cmd} gcloud projects list --format='json' --filter='name:#{ENV["TF_VAR_project_id"]}'`
  hash = JSON.parse(output)
  if hash.empty?
    puts "#{ENV["TF_VAR_project_id"]} not found, I'll create a new one"
    sh "
      #{@exekube_cmd} gcloud projects create #{ENV["TF_VAR_project_id"]} \
      --organization #{ENV["ORGANIZATION_ID"]} \
      --set-as-default"
  else
    sh "
      #{@exekube_cmd} gcloud config set project #{ENV["TF_VAR_project_id"]}"
  end
  sh "
    #{@exekube_cmd} gcloud beta billing projects link #{ENV["TF_VAR_project_id"]} \
    --billing-account #{ENV["BILLING_ID"]}"

  output = `#{@exekube_cmd} gcloud iam service-accounts list --format='json' \
            --filter='email:projectowner@#{ENV["TF_VAR_project_id"]}.iam.gserviceaccount.com'`
  hash = JSON.parse(output)
  if hash.empty?
    sh "#{@exekube_cmd} gcloud iam service-accounts create terraform \
        --display-name 'CI account'"
  end

  output = `#{@exekube_cmd} gcloud iam service-accounts keys list \
            --iam-account=projectowner@#{ENV["TF_VAR_project_id"]}.iam.gserviceaccount.com --format='json'`
  hash = JSON.parse(output)
  if hash.empty?
    puts "projectowner@#{ENV["TF_VAR_project_id"]}.iam.gserviceaccount.com NOT FOUND"
  else
    sh "#{@exekube_cmd} sh -c 'gcloud iam service-accounts keys create $TF_VAR_serviceaccount_key \
        --iam-account projectowner@#{ENV["TF_VAR_project_id"]}.iam.gserviceaccount.com'"
  end
  sh "#{@exekube_cmd} gcloud projects add-iam-policy-binding #{ENV["TF_VAR_project_id"]} \
            --member serviceAccount:projectowner@#{ENV["TF_VAR_project_id"]}.iam.gserviceaccount.com \
            --role roles/viewer"

  sh "#{@exekube_cmd} gcloud projects add-iam-policy-binding #{ENV["TF_VAR_project_id"]} \
            --member serviceAccount:projectowner@#{ENV["TF_VAR_project_id"]}.iam.gserviceaccount.com \
            --role roles/storage.admin"

  output = `#{@exekube_cmd} gcloud services list --format='json'`
  hash = JSON.parse(output)
  servicesEnabled = []
  hash.each do |service|
    servicesEnabled.push(service["serviceName"])
  end

  sh "#{@exekube_cmd} gcloud services enable cloudresourcemanager.googleapis.com" unless servicesEnabled.include?("cloudresourcemanager.googleapis.com")
  sh "#{@exekube_cmd} gcloud services enable cloudbilling.googleapis.com" unless servicesEnabled.include?("cloudbilling.googleapis.com")
  sh "#{@exekube_cmd} gcloud services enable iam.googleapis.com" unless servicesEnabled.include?("iam.googleapis.com")
  sh "#{@exekube_cmd} gcloud services enable compute.googleapis.com" unless servicesEnabled.include?("compute.googleapis.com")

  sh "#{@exekube_cmd} gcloud organizations add-iam-policy-binding #{ENV["ORGANIZATION_ID"]} \
      --member serviceAccount:projectowner@#{ENV["TF_VAR_project_id"]}.iam.gserviceaccount.com \
      --role roles/resourcemanager.projectCreator"

  sh "#{@exekube_cmd} gcloud organizations add-iam-policy-binding #{ENV["ORGANIZATION_ID"]} \
      --member serviceAccount:projectowner@#{ENV["TF_VAR_project_id"]}.iam.gserviceaccount.com \
      --role roles/billing.user"

  `#{@exekube_cmd} gsutil ls gs://#{ENV["TF_VAR_project_id"]}-tfstate`
  if $?.exitstatus != 0
    sh "#{@exekube_cmd} gsutil mb gs://#{ENV["TF_VAR_project_id"]}-tfstate"
  end

  sh "#{@exekube_cmd} gsutil versioning set on gs://#{ENV["TF_VAR_project_id"]}-tfstate"

end

desc "Get the credentials needed to create all the resources inside the project"
task :project_init => [:set_vars, @gcp_creds_file] do
  output = `#{@exekube_cmd} gcloud projects list --format='json' --filter='name:#{ENV["TF_VAR_project_id"]}'`
  hash = JSON.parse(output)
  if hash.empty?
    puts "#{ENV["TF_VAR_project_id"]} not found. Run infra_init task"
    exit
  else
    sh "
      #{@exekube_cmd} gcloud config set project #{ENV["TF_VAR_project_id"]}"
  end

  output = `#{@exekube_cmd} gcloud iam service-accounts keys list \
            --iam-account=projectowner@#{ENV["TF_VAR_project_id"]}.iam.gserviceaccount.com --format='json'`
  puts "#{@exekube_cmd} gcloud iam service-accounts keys list \
       --iam-account=projectowner@#{ENV["TF_VAR_project_id"]}.iam.gserviceaccount.com --format='json'"
  hash = JSON.parse(output)

  if hash.empty?
    puts "projectowner@#{ENV["TF_VAR_project_id"]}.iam.gserviceaccount.com NOT FOUND"
  else
    sh "#{@exekube_cmd} sh -c 'gcloud iam service-accounts keys create $TF_VAR_serviceaccount_key \
        --iam-account projectowner@#{ENV["TF_VAR_project_id"]}.iam.gserviceaccount.com'"
  end
end

# This duplicates information in docker-compose.yaml,
# TF_VAR_serviceaccount_key.
@serviceaccount_key_file = "secrets/kube-system/owner.json"
desc "[ADVANCED] Create credentials for projectowner service account"
task :creds => [:set_vars, @gcp_creds_file, @serviceaccount_key_file]
rule @serviceaccount_key_file do
  # TODO: This command is duplicated from exekube's gcp-project-init (and
  # hardcodes 'projectowner' instead of $SA_NAME which is only defined in
  # gcp-project-init). If gcp-project-init becomes idempotent (GPII-2989,
  # https://github.com/exekube/exekube/issues/92), or if this 'keys create'
  # step moves somewhere else in exekube, call this command from that place
  # instead.
  sh "
    #{@exekube_cmd} sh -c 'gcloud iam service-accounts keys create $TF_VAR_serviceaccount_key \
      --iam-account projectowner@$TF_VAR_project_id.iam.gserviceaccount.com'"
end
CLOBBER << @serviceaccount_key_file

desc "[ADVANCED] Tell gcloud to use TF_VAR_project_id as the default Project; can be useful after 'rake clobber'"
task :set_current_project => [:set_vars, @gcp_creds_file, @serviceaccount_key_file] do
  sh "#{@exekube_cmd} gcloud config set project #{ENV["TF_VAR_project_id"]}"
end

desc "[ADVANCED] Create or update low-level infrastructure"
task :apply_infra => [:set_vars, @gcp_creds_file, @serviceaccount_key_file] do
  sh "#{@exekube_cmd} up live/#{@env}/infra"
end

desc "[ONLY ADMINS] Create or update projects in the organization"
task :apply_projects => [:set_vars, @gcp_creds_file, @serviceaccount_key_file] do
  if @project_type != "common" or @env != "prd"
    puts "apply_projects task must run inside common/live/prd"
    exit
  end

  sh "#{@exekube_cmd} plan live/#{@env}/infra"
end

desc "Create cluster and deploy GPII components to it"
task :deploy => [:set_vars, @gcp_creds_file, @serviceaccount_key_file, @kubectl_creds_file, :apply_infra] do
  # Workaround for 'context deadline exceeded' issue:
  # https://github.com/exekube/exekube/issues/62
  # https://github.com/docker/for-mac/issues/2076
  # Remove this when docker for mac 18.05 becomes stable
  sh "docker run --rm --privileged alpine hwclock -s"
  sh_filter "#{@exekube_cmd} up"
end

desc "Destroy cluster and low-level infrastructure"
task :destroy_infra => [:set_vars, @gcp_creds_file, @serviceaccount_key_file, :destroy] do
  sh "#{@exekube_cmd} down live/#{@env}/infra"
end

desc "Undeploy GPII compoments and destroy cluster"
task :destroy => [:set_vars, @gcp_creds_file, @serviceaccount_key_file, @kubectl_creds_file] do
  sh "#{@exekube_cmd} down"
end

desc "[ADVANCED] Remove stale Terraform locks from GS -- for non-dev environments coordinate with the team first"
task :unlock => [:set_vars, @gcp_creds_file] do
  sh "#{@exekube_cmd} sh -c ' \
    for lock in $(gsutil ls -R gs://#{ENV["TF_VAR_project_id"]}-tfstate/#{@env}/ | grep .tflock); do \
      gsutil rm $lock; \
    done'"
end

desc '[ADVANCED] Run arbitrary exekube command -- rake xk"[kubectl get pods]"'
task :xk, [:cmd] => :set_vars do |taskname, args|
  if args[:cmd]
    cmd = args[:cmd]
  else
    puts "Argument :cmd -- the command to run inside the exekube container -- not present, defaulting to sh"
    cmd = "sh"
  end
  sh "#{@exekube_cmd} #{cmd}"
end

desc '[ADVANCED] Destroy provided module in the cluster, and then deploy it -- rake redeploy_module"[k8s/kube-system/cert-manager]"'
task :redeploy_module, [:module] => [:set_vars, @gcp_creds_file] do |taskname, args|
  Rake::Task[:destroy_module].invoke(args[:module])
  Rake::Task[:deploy_module].invoke(args[:module])
end

desc '[ADVANCED] Deploy provided module into the cluster -- rake deploy_module"[k8s/kube-system/cert-manager]"'
task :deploy_module, [:module] => [:set_vars, @gcp_creds_file] do |taskname, args|
  if args[:module].nil?
    puts "  ERROR: args[:module] must be set and point to Terragrunt directory!"
    raise ArgumentError, "args[:module] must be set"
  elsif !File.directory?(args[:module])
    puts "  ERROR: args[:module] must point to Terragrunt directory!"
    raise IOError, "args[:module] must point to existing Terragrunt directory"
  end
  sh_filter "#{@exekube_cmd} up live/#{@env}/#{args[:module]}"
end

desc '[ADVANCED] Destroy provided module in the cluster -- rake destroy_module"[k8s/kube-system/cert-manager]"'
task :destroy_module, [:module] => [:set_vars, @gcp_creds_file] do |taskname, args|
  if args[:module].nil?
    puts "  ERROR: args[:module] must be set and point to Terragrunt directory!"
    raise ArgumentError, "args[:module] must be set"
  elsif !File.directory?(args[:module])
    puts "  ERROR: args[:module] must point to Terragrunt directory!"
    raise IOError, "args[:module] must point to existing Terragrunt directory"
  end
  sh "#{@exekube_cmd} down live/#{@env}/#{args[:module]}"
end

# vim: et ts=2 sw=2:
