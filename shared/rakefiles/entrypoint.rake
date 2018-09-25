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

task :clean_volumes => :set_vars do
  ["helm", "terragrunt", "kube"].each do |app|
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
desc "[ADVANCED] Create and download credentials for projectowner service account"
task :configure_serviceaccount => [:set_vars] do
  sh "#{@exekube_cmd} rake configure_serviceaccount"
end

desc "[ADVANCED] Create or update low-level infrastructure"
task :apply_infra => [:set_vars, :configure_serviceaccount] do
  sh "#{@exekube_cmd} rake refresh_common_infra['#{@project_type}']"
  sh "#{@exekube_cmd} up live/#{@env}/infra"
end

desc "Create cluster and deploy GPII components to it"
task :deploy => [:set_vars, :apply_infra] do
  # Workaround for 'context deadline exceeded' issue:
  # https://github.com/exekube/exekube/issues/62
  # https://github.com/docker/for-mac/issues/2076
  # Remove this when docker for mac 18.05 becomes stable
  sh "docker run --rm --privileged alpine hwclock -s"
  sh "#{@exekube_cmd} rake xk[up]"
end

desc "Undeploy GPII compoments and destroy cluster"
task :destroy => [:set_vars] do
  sh "#{@exekube_cmd} rake xk[down]"
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

desc "[ADVANCED] Run arbitrary command in exekube container via rake wrapper (with secrets set) -- rake sh['kubectl exec --n gpii couchdb-couchdb-0 -c \
couchdb -- curl -s http://$TF_VAR_secret_couchdb_admin_username:$TF_VAR_secret_couchdb_admin_password@127.0.0.1:5984/gpii/_all_docs']"
task :sh, [:cmd] => [:set_vars] do |taskname, args|
  if args[:cmd]
    cmd = args[:cmd]
  else
    puts "Argument :cmd -- the command to run inside the exekube container -- not present, defaulting to bash"
    cmd = "bash"
  end
  sh "#{@exekube_cmd} rake xk['#{cmd}',skip_secret_mgmt,preserve_stderr]"
end

desc "[ADVANCED] Run arbitrary command in exekube container via plain shell -- rake plain_sh['kubectl --namespace gpii get pods']"
task :plain_sh, [:cmd] => [:set_vars] do |taskname, args|
  if args[:cmd]
    cmd = args[:cmd]
  else
    puts "Argument :cmd -- the command to run inside the exekube container -- not present, defaulting to bash"
    cmd = "bash"
  end
  sh "#{@exekube_cmd} #{cmd}"
end

desc "[ADVANCED] Destroy all SA keys except current one"
task :destroy_sa_keys => [:set_vars] do
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
task :destroy_secrets, [:encryption_key] => [:set_vars] do |taskname, args|
  sh "#{@exekube_cmd} sh -c ' \
    for secret_bucket in $(gsutil ls -p #{ENV["TF_VAR_project_id"]} | grep #{args[:encryption_key]}-secrets/); do \
      for secret_file in $(gsutil ls -R $secret_bucket | grep yaml); do \
        gsutil rm $secret_file; \
      done \
    done'"
end

desc "[ADVANCED] Destroy Terraform state stored in GS bucket for prefix, passed as argument -- rake destroy_tfstate['k8s']"
task :destroy_tfstate, [:prefix] => [:set_vars] do |taskname, args|
  if args[:prefix].nil? || args[:prefix].size == 0
    puts "Argument :prefix not present, defaulting to k8s"
    prefix = "k8s"
  else
    prefix = args[:prefix]
  end
  sh "#{@exekube_cmd} sh -c 'gsutil rm -r gs://#{ENV["TF_VAR_project_id"]}-tfstate/#{@env}/#{prefix}'"
  sh "docker volume rm -f -- #{ENV["TF_VAR_project_id"]}-#{ENV["USER"]}-terragrunt"
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
task :destroy_module, [:module] => [:set_vars] do |taskname, args|
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
