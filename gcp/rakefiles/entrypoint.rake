require "rake/clean"

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

task :clean_volumes => :set_vars do
  sh "docker volume rm -f -- #{ENV["TF_VAR_project_id"]}-#{ENV["USER"]}-helm"
  sh "docker volume rm -f -- #{ENV["TF_VAR_project_id"]}-#{ENV["USER"]}-terragrunt"
  sh "docker volume rm -f -- #{ENV["TF_VAR_project_id"]}-#{ENV["USER"]}-kube"
end
Rake::Task["clean"].enhance do
  Rake::Task["clean_volumes"].invoke
end

task :clobber_volumes => :set_vars do
  sh "docker volume rm -f -- #{ENV["TF_VAR_project_id"]}-#{ENV["USER"]}-secrets"
  sh "docker volume rm -f -- #{ENV["TF_VAR_project_id"]}-#{ENV["USER"]}-gcloud"
end
Rake::Task["clobber"].enhance do
  Rake::Task["clobber_volumes"].invoke
end

desc "Create cluster and deploy GPII components to it"
task :default => :deploy

task :set_vars do
  Vars.set_vars(@env, @project_type)
  Vars.set_versions()
  @secrets = Secrets.collect_secrets()
  Rake::Task[:set_compose_env].invoke
end

@compose_env_file = "compose.env"
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

desc "Authenticate and generate GCP credentials (gcloud auth login)"
task :configure_login => [:set_vars] do
  # This authenticates to GCP/the `gcloud` command in the normal, interactive
  # way. This is the default method, best for human users.
  sh "#{@exekube_cmd} gcloud auth login"
end

desc "[ADVANCED] Fetch kubectl credentials (gcloud auth login)"
task :configure_kubectl => [:set_vars] do
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

# This duplicates information in docker-compose.yaml,
# TF_VAR_serviceaccount_key.
@serviceaccount_key_file = "/project/live/#{@env}/secrets/kube-system/owner.json"
desc "[ADVANCED] Create and download credentials for projectowner service account"
task :configure_serviceaccount => [:set_vars] do
  # TODO: This command is duplicated from exekube's gcp-project-init (and
  # hardcodes 'projectowner' instead of $SA_NAME which is only defined in
  # gcp-project-init). If gcp-project-init becomes idempotent (GPII-2989,
  # https://github.com/exekube/exekube/issues/92), or if this 'keys create'
  # step moves somewhere else in exekube, call this command from that place
  # instead.
  sh "
    #{@exekube_cmd} sh -c '
      [ -f $TF_VAR_serviceaccount_key ] || \
        gcloud iam service-accounts keys create $TF_VAR_serviceaccount_key \
        --iam-account projectowner@$TF_VAR_project_id.iam.gserviceaccount.com'"
end

desc "[EXPERT] Copy GCP credentials from local storage on CI worker"
task :configure_serviceaccount_ci => [:set_vars] do
  # The automated CI process cannot (and does not want to) authenticate in the
  # normal, interactive way. Instead, we will fetch previously downloaded
  # credentials, copy them to the expected place, and activate them for later
  # use by `gcloud` commands.
  #
  # Another way to think of it: this task uses an alternate strategy to
  # accomplish the same result as @serviceaccount_key_file.
  FileUtils.mkdir_p(File.dirname(@serviceaccount_key_file))
  FileUtils.install("#{Dir.home}/.ssh/gcp-config/#{@env}/owner.json", "#{@serviceaccount_key_file}", :mode => 0400)
  sh "#{@exekube_cmd} sh -c 'gcloud auth activate-service-account --key-file $TF_VAR_serviceaccount_key --project $TF_VAR_project_id'"
end

desc "[ADVANCED] Tell gcloud to use TF_VAR_project_id as the default Project; can be useful after 'rake clobber'"
task :configure_current_project => [:set_vars] do
  sh "#{@exekube_cmd} gcloud config set project #{ENV["TF_VAR_project_id"]}"
end

desc "[NOT IDEMPOTENT, RUN ONCE PER ENVIRONMENT] Initialize GCP Project where this environment's resources will live"
task :project_init => [:set_vars] do
  sh "#{@exekube_cmd} gcp-project-init"
end

desc "[ADVANCED] Create or update infrastructure for secret management, this has no corresponding destroy task"
task :apply_secret_mgmt => [:set_vars, :configure_serviceaccount] do
  sh "#{@exekube_cmd} up live/#{@env}/secret-mgmt"
end

desc "[ADVANCED] Create or update low-level infrastructure"
task :apply_infra => [:set_vars, :configure_serviceaccount] do
  sh "#{@exekube_cmd} up live/#{@env}/infra"
end

desc "Create cluster and deploy GPII components to it"
task :deploy => [:set_vars, :configure_serviceaccount, :configure_kubectl, :apply_infra, :set_secrets] do
  # Workaround for 'context deadline exceeded' issue:
  # https://github.com/exekube/exekube/issues/62
  # https://github.com/docker/for-mac/issues/2076
  # Remove this when docker for mac 18.05 becomes stable
  sh "docker run --rm --privileged alpine hwclock -s"
  sh "#{@exekube_cmd} rake xk[up]"
end

desc "Undeploy GPII compoments and destroy cluster"
task :destroy => [:set_vars, :configure_serviceaccount, :configure_kubectl, :set_secrets] do
  sh "#{@exekube_cmd} rake xk[down]"
end

desc "[ADVANCED] Create or update low-level infrastructure"
task :apply_infra => [:set_vars, @gcp_creds_file, @serviceaccount_key_file] do
  sh "#{@exekube_cmd} up live/#{@env}/infra"
end

desc "Destroy cluster and low-level infrastructure"
task :destroy_infra => [:set_vars, :configure_serviceaccount, :destroy] do
  sh "#{@exekube_cmd} down live/#{@env}/infra"
end

desc "[ADVANCED] Remove stale Terraform locks from GS -- for non-dev environments coordinate with the team first"
task :unlock => [:set_vars] do
  sh "#{@exekube_cmd} sh -c ' \
    for lock in $(gsutil ls -R gs://#{ENV["TF_VAR_project_id"]}-tfstate/#{@env}/ | grep .tflock); do \
      gsutil rm $lock; \
    done'"
end

desc '[ADVANCED] Run arbitrary exekube command -- rake sh["kubectl --namespace gpii get pods"]'
task :sh, [:cmd] => [:set_vars] do |taskname, args|
  if args[:cmd]
    cmd = args[:cmd]
  else
    puts "Argument :cmd -- the command to run inside the exekube container -- not present, defaulting to bash"
    cmd = "bash"
  end
  sh "#{@exekube_cmd} rake xk['#{cmd}',skip_infra,skip_secret_mgmt]"
end

desc '[ADVANCED] Destroy secrets file stored in GS bucket for encryption key, passed as argument -- rake destroy_secrets"[default]"'
task :destroy_secrets, [:encryption_key] => [:set_vars] do |taskname, args|
  if args[:encryption_key].nil?
    puts "  ERROR: args[:encryption_key] must be set!"
    raise ArgumentError, "args[:encryption_key] must be set"
  end
  sh "#{@exekube_cmd} sh -c ' \
    for secret_file in $(gsutil ls -R gs://#{ENV["TF_VAR_project_id"]}-#{args[:encryption_key]}-secrets/ | grep yaml); do \
      gsutil rm $secret_file; \
    done'"
end

desc '[ADVANCED] Destroy Terraform state stored in GS bucket for prefix, passed as argument -- rake destroy_tfstate"[k8s]"'
task :destroy_tfstate, [:prefix] => [:set_vars, @gcp_creds_file] do |taskname, args|
  if args[:prefix].nil? || args[:prefix].size == 0
    puts "  ERROR: args[:prefix] must be set!"
    raise ArgumentError, "args[:prefix] must be set"
  end
  sh "#{@exekube_cmd} sh -c 'gsutil -m rm -r gs://#{ENV["TF_VAR_project_id"]}-tfstate/#{@env}/#{args[:prefix]}'"
  sh "docker volume rm -f -- #{ENV["TF_VAR_project_id"]}-#{ENV["USER"]}-terragrunt"
end

desc '[ADVANCED] Destroy provided module in the cluster, and then deploy it -- rake redeploy_module"[k8s/kube-system/cert-manager]"'
task :redeploy_module, [:module] => [:set_vars] do |taskname, args|
  Rake::Task[:destroy_module].invoke(args[:module])
  Rake::Task[:deploy_module].invoke(args[:module])
end

desc '[ADVANCED] Deploy provided module into the cluster -- rake deploy_module"[k8s/kube-system/cert-manager]"'
task :deploy_module, [:module] => [:set_vars, :configure_kubectl, :set_secrets] do |taskname, args|
  if args[:module].nil?
    puts "  ERROR: args[:module] must be set and point to Terragrunt directory!"
    raise
  elsif !File.directory?(args[:module])
    puts "  ERROR: args[:module] must point to Terragrunt directory!"
    raise
  end
  sh "#{@exekube_cmd} rake xk['up live/#{@env}/#{args[:module]}',skip_infra,skip_secret_mgmt]"
end

desc '[ADVANCED] Destroy provided module in the cluster -- rake destroy_module"[k8s/kube-system/cert-manager]"'
task :destroy_module, [:module] => [:set_vars, :configure_kubectl, :set_secrets] do |taskname, args|
  if args[:module].nil?
    puts "  ERROR: args[:module] must be set and point to Terragrunt directory!"
    raise
  elsif !File.directory?(args[:module])
    puts "  ERROR: args[:module] must point to Terragrunt directory!"
    raise
  end
  sh "#{@exekube_cmd} rake xk['down live/#{@env}/#{args[:module]}',skip_infra,skip_secret_mgmt]"
end

# vim: et ts=2 sw=2:
