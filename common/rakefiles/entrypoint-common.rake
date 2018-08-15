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
    Rake::Task[:set_current_project].invoke
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

  Rake::Task[:creds].invoke

  sh "#{@exekube_cmd} gcloud projects add-iam-policy-binding #{ENV["TF_VAR_project_id"]} \
            --member serviceAccount:projectowner@#{ENV["TF_VAR_project_id"]}.iam.gserviceaccount.com \
            --role roles/viewer"

  sh "#{@exekube_cmd} gcloud projects add-iam-policy-binding #{ENV["TF_VAR_project_id"]} \
            --member serviceAccount:projectowner@#{ENV["TF_VAR_project_id"]}.iam.gserviceaccount.com \
            --role roles/storage.admin"

  sh "#{@exekube_cmd} gcloud projects add-iam-policy-binding #{ENV["TF_VAR_project_id"]} \
            --member serviceAccount:projectowner@#{ENV["TF_VAR_project_id"]}.iam.gserviceaccount.com \
            --role roles/dns.admin"

  output = `#{@exekube_cmd} gcloud services list --format='json'`
  hash = JSON.parse(output)

  ["cloudresourcemanager.googleapis.com",
   "cloudbilling.googleapis.com",
   "iam.googleapis.com",
   "dns.googleapis.com",
   "compute.googleapis.com"].each do |service|
     sh "#{@exekube_cmd} gcloud services enable #{service}" unless hash.any? { |s| s['serviceName'] == service }
  end

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

desc "[ONLY ADMINS] Create or update projects in the organization"
task :apply_projects => [:set_vars, @gcp_creds_file, @serviceaccount_key_file] do
  if @project_type != "common" or @env != "prd"
    puts "apply_projects task must run inside common/live/prd"
    exit
  end

  sh "#{@exekube_cmd} up live/#{@env}/infra"
end
