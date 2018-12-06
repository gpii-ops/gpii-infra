require "rake/clean"

import "../../../shared/rakefiles/ci.rake"
import "../../../shared/rakefiles/test.rake"

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

@exekube_cmd = "docker-compose run --rm xk"

@serviceaccount_key_file = "secrets/kube-system/owner.json"

desc "Pull the current exekube container from the Docker hub"
task :update_exekube => :set_vars do
  sh "docker-compose pull"
end

task :clean_volumes => :set_vars do
  ["helm", "kube", "locust_tasks"].each do |app|
    sh "docker volume rm -f -- #{ENV["TF_VAR_project_id"]}-#{ENV["USER"]}-#{app}"
  end
end
Rake::Task["clean"].enhance do
  Rake::Task["clean_volumes"].invoke
end

task :clobber_volumes => :set_vars do
  ["secrets", "gcloud", "aws"].each do |app|
    sh "docker volume rm -f -- #{ENV["TF_VAR_project_id"]}-#{ENV["USER"]}-#{app}"
  end
end
Rake::Task["clobber"].enhance do
  Rake::Task["clobber_volumes"].invoke
end

desc "Create cluster and deploy GPII components to it"
task :default => :deploy

task :set_vars do
  Vars.set_vars(@env, @project_type)
  Vars.set_versions()
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

desc "[ADVANCED] Authenticate and generate GCP credentials (gcloud auth login)"
task :configure_login => [:set_vars] do
  sh "#{@exekube_cmd} rake configure_login"
end

# This duplicates information in docker-compose.yaml,
# TF_VAR_serviceaccount_key.
desc "[ADVANCED] Create service account for authenticated user and download credentials"
task :configure_serviceaccount, [:use_projectowner_sa] => [:set_vars] do |taskname, args|
  if args[:use_projectowner_sa]
    sh "#{@exekube_cmd} rake configure_serviceaccount[use_projectowner_sa]"
  else
    sh "#{@exekube_cmd} rake configure_serviceaccount"
  end
end

desc "[ADVANCED] Destroy authenticated user's service account and remove stored credentials"
task :destroy_serviceaccount => [:set_vars, :check_destroy_allowed] do
  sh "#{@exekube_cmd} rake destroy_serviceaccount"
end

desc "[ADVANCED] Create or update low-level infrastructure"
task :apply_infra => [:set_vars, :configure_serviceaccount] do
  sh "#{@exekube_cmd} rake refresh_common_infra['#{@project_type}']"
  sh "#{@exekube_cmd} up live/#{@env}/infra"
end

desc "Create cluster and deploy GPII components to it"
task :deploy => [:set_vars, :apply_infra] do
  sh "#{@exekube_cmd} rake xk[up]"
  Rake::Task["display_cluster_info"].invoke
end

desc "Display some handy info about the cluster"
task :display_cluster_info do
  puts
  puts
  puts "*************************************************"
  puts "Congratulations! Your GPII Cloud in GCP is ready!"
  puts "*************************************************"
  puts
  puts "GCP Dashboard:"
  puts "  https://console.cloud.google.com/home/dashboard?organizationId=#{ ENV["TF_VAR_organization_id"] }&project=#{ ENV["TF_VAR_project_id"] }"
  puts
  puts "Stackdriver Logging Dashboard:"
  puts "  https://console.cloud.google.com/logs/viewer?project=#{ ENV["TF_VAR_project_id"] }&organizationId=#{ ENV["TF_VAR_organization_id"] }"
  puts
  puts "Stackdriver Monitoring Dashboard:"
  puts "  https://app.google.stackdriver.com/?project=#{ ENV["TF_VAR_project_id"] }"
  puts
  puts "Preferences endpoint:"
  puts "  curl -k https://preferences.#{ENV["TF_VAR_domain_name"] }/preferences/carla"
  puts
  puts "Flowmanager endpoint:"
  puts "  curl -k https://flowmanager.#{ENV["TF_VAR_domain_name"] }"
  puts
  puts "Run `rake destroy` to delete all the expensive resources created by the deployment"
  puts
end

task :check_destroy_allowed do
  if ["prd"].include?(@env)
    if ENV["RAKE_REALLY_DESTROY_IN_PRD"].nil?
      puts "  ERROR: Tried to destroy something in env 'prd' but RAKE_REALLY_DESTROY_IN_PRD is not set"
      raise ArgumentError, "Tried to destroy something in env 'prd' but RAKE_REALLY_DESTROY_IN_PRD is not set"
    end
  end
end

desc "Undeploy GPII compoments and destroy cluster"
task :destroy => [:set_vars, :check_destroy_allowed] do
  sh "#{@exekube_cmd} rake xk[down]"
end

desc "Destroy cluster and low-level infrastructure"
task :destroy_infra => [:set_vars, :check_destroy_allowed, :configure_serviceaccount, :destroy] do
  sh "#{@exekube_cmd} down live/#{@env}/infra"
end

desc "[ADVANCED] Remove stale Terraform locks from GS -- for non-dev environments coordinate with the team first"
task :unlock => [:set_vars] do
  sh "#{@exekube_cmd} sh -c ' \
    for lock in $(gsutil ls -R gs://#{ENV["TF_VAR_project_id"]}-tfstate/#{@env}/ | grep .tflock); do \
      gsutil rm $lock; \
    done'"
end

desc "[ADVANCED] Run arbitrary command in exekube container via rake wrapper (with secrets set) -- rake sh['kubectl exec --n gpii couchdb-couchdb-0 -c \
couchdb -- curl -s http://$TF_VAR_secret_couchdb_admin_username:$TF_VAR_secret_couchdb_admin_password@127.0.0.1:5984/gpii/_all_docs']"
task :sh, [:cmd] => [:set_vars] do |taskname, args|
  if args[:cmd]
    cmd = args[:cmd]
  else
    puts "Argument :cmd -- the command to run inside the exekube container -- not present, defaulting to 'bash'"
    cmd = "bash"
  end
  sh "#{@exekube_cmd} rake xk['#{cmd}',skip_secret_mgmt,preserve_stderr]"
end

desc "[ADVANCED] Run arbitrary command in exekube container via plain shell -- rake plain_sh['kubectl --namespace gpii get pods']"
task :plain_sh, [:cmd] => [:set_vars] do |taskname, args|
  if args[:cmd]
    cmd = args[:cmd]
  else
    puts "Argument :cmd -- the command to run inside the exekube container -- not present, defaulting to 'bash'"
    cmd = "bash"
  end
  sh "#{@exekube_cmd} #{cmd}"
end

desc "[ADVANCED] Destroy all projectowner's SA keys except current one"
task :destroy_sa_keys => [:set_vars, :check_destroy_allowed] do
  sh "#{@exekube_cmd} sh -c ' \
    existing_keys=$(gcloud iam service-accounts keys list \
      --iam-account projectowner@$TF_VAR_project_id.iam.gserviceaccount.com \
      --managed-by user | grep -oE \"^[a-z0-9]+\"); \
    current_key=$(cat $TF_VAR_serviceaccount_key 2>/dev/null | jq -r '.private_key_id'); \
    for key in $existing_keys; do \
      if [ \"$key\" != \"$current_key\" ]; then \
        yes | gcloud iam service-accounts keys delete \
          --iam-account projectowner@$TF_VAR_project_id.iam.gserviceaccount.com $key; \
      fi \
    done'"
end

desc "[ADVANCED] Destroy secrets file stored in GS bucket for encryption key, passed as argument -- rake destroy_secrets['default']"
task :destroy_secrets, [:encryption_key] => [:set_vars, :check_destroy_allowed] do |taskname, args|
  sh "#{@exekube_cmd} sh -c ' \
    for secret_bucket in $(gsutil ls -p #{ENV["TF_VAR_project_id"]} | grep #{args[:encryption_key]}-secrets/); do \
      for secret_file in $(gsutil ls -R $secret_bucket | grep yaml); do \
        gsutil rm $secret_file; \
      done \
    done'"
end

desc "[ADVANCED] Destroy Terraform state stored in GS bucket for prefix, passed as argument -- rake destroy_tfstate['k8s']"
task :destroy_tfstate, [:prefix] => [:set_vars, :check_destroy_allowed] do |taskname, args|
  if args[:prefix].nil? || args[:prefix].size == 0
    puts "Argument :prefix not present, defaulting to 'k8s'"
    prefix = "k8s"
  else
    prefix = args[:prefix]
  end
  sh "#{@exekube_cmd} sh -c 'gsutil rm -r gs://#{ENV["TF_VAR_project_id"]}-tfstate/#{@env}/#{prefix}'"
end

desc "[ADVANCED] Rotate Terraform state key for prefix, passed as argument -- rake rotate_tfstate_key['k8s']"
task :rotate_tfstate_key, [:prefix] => [:set_vars, :check_destroy_allowed] do |taskname, args|
  if args[:prefix].nil? || args[:prefix].size == 0
    puts "Argument :prefix not present, defaulting to 'k8s'"
    prefix = "k8s"
  else
    prefix = args[:prefix]
  end
  sh "#{@exekube_cmd} rake rotate_secret['default','key_tfstate_encryption_key','sh -c \"gsutil \
       -o GSUtil:decryption_key1=$TF_VAR_key_tfstate_encryption_key_rotated \
       -o GSUtil:encryption_key=$TF_VAR_key_tfstate_encryption_key \
       rewrite -k -r gs://#{ENV["TF_VAR_project_id"]}-tfstate/#{@env}/#{prefix}\"',skip_secret_mgmt,preserve_stderr]"
end

desc "[ADVANCED] Rotate provided KMS key and re-encrypt its associated secrets file in GS bucket -- rake rotate_secrets_key['default']"
task :rotate_secrets_key, [:kms_key] => [:set_vars, :check_destroy_allowed] do |taskname, args|
  if args[:kms_key].nil? || args[:kms_key].size == 0
    puts "Argument :kms_key not present, defaulting to 'default'"
    kms_key = "default"
  else
    kms_key = args[:kms_key]
  end
  sh "#{@exekube_cmd} rake rotate_secrets_key['#{kms_key}']"
end

desc "[ADVANCED] Destroy provided module in the cluster, and then deploy it -- rake redeploy_module['k8s/kube-system/cert-manager']"
task :redeploy_module, [:module] => [:set_vars] do |taskname, args|
  Rake::Task[:destroy_module].invoke(args[:module])
  Rake::Task[:deploy_module].invoke(args[:module])
end

desc "[ADVANCED] Deploy provided module into the cluster -- rake deploy_module['k8s/kube-system/cert-manager']"
task :deploy_module, [:module] => [:set_vars] do |taskname, args|
  if args[:module].nil?
    puts "  ERROR: args[:module] must be set and point to Terragrunt directory!"
    raise
  elsif !File.directory?(args[:module])
    puts "  ERROR: args[:module] must point to Terragrunt directory!"
    raise
  end
  sh "#{@exekube_cmd} rake xk['up live/#{@env}/#{args[:module]}',skip_secret_mgmt]"
end

desc "[ADVANCED] Destroy provided module in the cluster -- rake destroy_module['k8s/kube-system/cert-manager']"
task :destroy_module, [:module] => [:set_vars, :check_destroy_allowed] do |taskname, args|
  if args[:module].nil?
    puts "  ERROR: args[:module] must be set and point to Terragrunt directory!"
    raise
  elsif !File.directory?(args[:module])
    puts "  ERROR: args[:module] must point to Terragrunt directory!"
    raise
  end
  sh "#{@exekube_cmd} rake xk['down live/#{@env}/#{args[:module]}',skip_secret_mgmt]"
end

# vim: et ts=2 sw=2:
