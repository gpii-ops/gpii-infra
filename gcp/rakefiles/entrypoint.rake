require "rake/clean"
require_relative "./vars.rb"

if @env.nil?
  puts "  ERROR: @env must be set!"
  puts "  This is a problem in rake code."
  puts "  Set @env before importing this rakefile."
  raise ArgumentError, "@env must be set"
end

@exekube_cmd = "docker-compose run --rm --service-ports xk"

desc "Create cluster and deploy GPII components to it"
task :default => :deploy

task :set_vars do
  Vars.set_vars(@env)
end

@gcp_creds_path = "../../.config/#{@env}/gcloud"
@gcp_creds_file = "#{@gcp_creds_path}/credentials.db"
desc "[ADVANCED] Authenticate and generate GCP credentials (gcloud auth login)"
task :auth => [:set_vars, @gcp_creds_file]
rule @gcp_creds_file do
  sh "#{@exekube_cmd} gcloud auth login"
end
CLOBBER << @gcp_creds_path

desc "[NOT IDEMPOTENT, RUN ONCE PER ENVIRONMENT] Initialize GCP Project where this environment's resources will live"
task :project_init => [:set_vars, @gcp_creds_file] do
  sh "#{@exekube_cmd} gcp-project-init"
  # TODO: Move this to exekube gcp-project-init instead?
  # https://github.com/exekube/exekube/issues/90
  sh "#{@exekube_cmd} gcloud services enable serviceusage.googleapis.com"
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

desc "Create cluster and deploy GPII components to it"
task :deploy => [:set_vars, @gcp_creds_file, @serviceaccount_key_file, :apply_infra] do
  sh "#{@exekube_cmd} up"
end

desc "Destroy cluster and low-level infrastructure"
task :destroy => [:set_vars, @gcp_creds_file, @serviceaccount_key_file, :destroy_cluster] do
  sh "#{@exekube_cmd} down live/#{@env}/infra"
end

desc "Destroy cluster"
task :destroy_cluster => [:set_vars, @gcp_creds_file, @serviceaccount_key_file] do
  sh "#{@exekube_cmd} down"
end

desc "[ADVANCED] Interactive exekube shell"
task :xk_sh => :set_vars do
  sh "#{@exekube_cmd} sh"
end


# vim: et ts=2 sw=2:
