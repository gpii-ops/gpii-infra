require "rake/clean"

require_relative "./secrets.rb"
require_relative "./sh_filter.rb"
require_relative "./vars.rb"

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

@dot_config_path = "../../.config/#{@env}"
directory @dot_config_path
CLOBBER << @dot_config_path

desc "Create cluster and deploy GPII components to it"
task :default => :deploy

task :set_vars => [@dot_config_path] do
  Vars.set_vars(@env, @project_type)
  Vars.set_versions()
  @secrets = Secrets.collect_secrets()
  Rake::Task[:set_compose_env].invoke
end

@compose_env_file = "#{@dot_config_path}/compose.env"
CLEAN << @compose_env_file
# We do this with a task rather than a rule so that compose_env_file is always
# re-written.
task :set_compose_env do
  tf_vars = []
  ENV.each do |key, val|
   tf_vars << key if key.start_with?("TF_VAR_")
  end
  File.open(@compose_env_file, 'w') do |file|
    file.write(tf_vars.sort.join("\n"))
  end
end

task :set_secrets, [:skip_secret_mgmt] do |taskname, args|
  Rake::Task[:apply_secret_mgmt].invoke unless args[:skip_secret_mgmt]
  Secrets.set_secrets(@secrets, @exekube_cmd)
end

@gcp_creds_file = "#{@dot_config_path}/gcloud/credentials.db"
desc "[ADVANCED] Authenticate and generate GCP credentials (gcloud auth login)"
task :configure_login => [:set_vars, @gcp_creds_file]
rule @gcp_creds_file do
  # This authenticates to GCP/the `gcloud` command in the normal, interactive
  # way. This is the default method, best for human users.
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

@serviceaccount_key_file = "secrets/kube-system/owner.json"
desc "[ADVANCED] Create and download credentials for projectowner service account"
task :configure_serviceaccount => [:set_vars, @gcp_creds_file, @serviceaccount_key_file]
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

desc "[EXPERT] Copy GCP credentials from local storage on CI worker"
task :configure_serviceaccount_ci => [:set_vars, @dot_config_path] do
  # The automated CI process cannot (and does not want to) authenticate in the
  # normal, interactive way. Instead, we will fetch previously downloaded
  # credentials, copy them to the expected place, and activate them for later
  # use by `gcloud` commands.
  #
  # Another way to think of it: this task uses an alternate strategy to build
  # @gcp_creds_file and @serviceaccount_key_file.
  FileUtils.mkdir_p(File.dirname(@serviceaccount_key_file))
  FileUtils.install("#{Dir.home}/.ssh/gcp-config/#{@env}/owner.json", "#{@serviceaccount_key_file}", :mode => 0400)
  sh "#{@exekube_cmd} sh -c 'gcloud auth activate-service-account --key-file $TF_VAR_serviceaccount_key --project $TF_VAR_project_id'"
end

desc "[ADVANCED] Tell gcloud to use TF_VAR_project_id as the default Project; can be useful after 'rake clobber'"
task :configure_current_project => [:set_vars, @gcp_creds_file, @serviceaccount_key_file] do
  sh "#{@exekube_cmd} gcloud config set project #{ENV["TF_VAR_project_id"]}"
end

desc "[NOT IDEMPOTENT, RUN ONCE PER ENVIRONMENT] Initialize GCP Project where this environment's resources will live"
task :project_init => [:set_vars, @gcp_creds_file] do
  sh "#{@exekube_cmd} gcp-project-init"
end

desc "[ADVANCED] Create or update infrastructure for secret management, this has no corresponding destroy task"
task :apply_secret_mgmt => [:set_vars, @gcp_creds_file, @serviceaccount_key_file] do
  sh "#{@exekube_cmd} up live/#{@env}/secret-mgmt"
end

desc "[ADVANCED] Create or update low-level infrastructure"
task :apply_infra => [:set_vars, @gcp_creds_file, @serviceaccount_key_file] do
  sh "#{@exekube_cmd} up live/#{@env}/infra"
end

desc "Create cluster and deploy GPII components to it"
task :deploy => [:set_vars, @gcp_creds_file, @serviceaccount_key_file, @kubectl_creds_file, :apply_infra, :set_secrets] do
  # Workaround for 'context deadline exceeded' issue:
  # https://github.com/exekube/exekube/issues/62
  # https://github.com/docker/for-mac/issues/2076
  # Remove this when docker for mac 18.05 becomes stable
  sh "docker run --rm --privileged alpine hwclock -s"
  sh_filter "#{@exekube_cmd} up"
end

desc "Undeploy GPII compoments and destroy cluster"
task :destroy => [:set_vars, @gcp_creds_file, @serviceaccount_key_file, @kubectl_creds_file, :set_secrets] do
  # Terraform will fail if template files are missing, and since values_dir is not mounted
  # from host machine anymore, all templates vanish after docker-compose container is terminated.
  # So we have to invoke templater with the main exekube command
  sh "#{@exekube_cmd} sh -c 'xk up live/#{@env}/k8s/templater && xk down'"
end

desc "Destroy cluster and low-level infrastructure"
task :destroy_infra => [:set_vars, @gcp_creds_file, @serviceaccount_key_file, :destroy] do
  sh "#{@exekube_cmd} down live/#{@env}/infra"
end

desc "[ADVANCED] Remove stale Terraform locks from GS -- for non-dev environments coordinate with the team first"
task :unlock => [:set_vars, @gcp_creds_file] do
  sh "#{@exekube_cmd} sh -c ' \
    for lock in $(gsutil ls -R gs://#{ENV["TF_VAR_project_id"]}-tfstate/#{@env}/ | grep .tflock); do \
      gsutil rm $lock; \
    done'"
end

desc '[ADVANCED] Run arbitrary exekube command -- rake xk"[kubectl get pods]"'
task :xk, [:cmd] => [:set_vars] do |taskname, args|
  puts "If this hangs or fails, try running 'rake apply_secret_mgmt'"
  Rake::Task[:set_secrets].invoke(true)
  if args[:cmd]
    cmd = args[:cmd]
  else
    puts "Argument :cmd -- the command to run inside the exekube container -- not present, defaulting to sh"
    cmd = "sh"
  end
  sh "#{@exekube_cmd} #{cmd}"
end

desc '[ADVANCED] Destroy secrets file stored in GS bucket for encryption key, passed as argument -- rake destroy_secrets"[default]"'
task :destroy_secrets, [:encryption_key] => [:set_vars, @gcp_creds_file] do |taskname, args|
  if args[:encryption_key].nil?
    puts "  ERROR: args[:encryption_key] must be set!"
    raise ArgumentError, "args[:encryption_key] must be set"
  end
  sh "#{@exekube_cmd} sh -c ' \
    for secret_file in $(gsutil ls -R gs://#{ENV["TF_VAR_project_id"]}-#{args[:encryption_key]}-secrets/ | grep #{Secrets::SECRETS_FILE}); do \
      gsutil rm $secret_file; \
    done'"
end

desc '[ADVANCED] Destroy provided module in the cluster, and then deploy it -- rake redeploy_module"[k8s/kube-system/cert-manager]"'
task :redeploy_module, [:module] => [:set_vars, @gcp_creds_file] do |taskname, args|
  Rake::Task[:destroy_module].invoke(args[:module])
  Rake::Task[:deploy_module].invoke(args[:module])
end

desc '[ADVANCED] Deploy provided module into the cluster -- rake deploy_module"[k8s/kube-system/cert-manager]"'
task :deploy_module, [:module] => [:set_vars, @gcp_creds_file, :set_secrets] do |taskname, args|
  if args[:module].nil?
    puts "  ERROR: args[:module] must be set and point to Terragrunt directory!"
    raise ArgumentError, "args[:module] must be set"
  elsif !File.directory?(args[:module])
    puts "  ERROR: args[:module] must point to Terragrunt directory!"
    raise IOError, "args[:module] must point to existing Terragrunt directory"
  end
  sh_filter "#{@exekube_cmd} sh -c 'xk up live/#{@env}/k8s/templater && xk up live/#{@env}/#{args[:module]}'"
end

desc '[ADVANCED] Destroy provided module in the cluster -- rake destroy_module"[k8s/kube-system/cert-manager]"'
task :destroy_module, [:module] => [:set_vars, @gcp_creds_file, :set_secrets] do |taskname, args|
  if args[:module].nil?
    puts "  ERROR: args[:module] must be set and point to Terragrunt directory!"
    raise ArgumentError, "args[:module] must be set"
  elsif !File.directory?(args[:module])
    puts "  ERROR: args[:module] must point to Terragrunt directory!"
    raise IOError, "args[:module] must point to existing Terragrunt directory"
  end
  sh_filter "#{@exekube_cmd} sh -c 'xk up live/#{@env}/k8s/templater && xk down live/#{@env}/#{args[:module]}'"
end

# vim: et ts=2 sw=2:
