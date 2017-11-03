# We need a DNS zone before kops will do anything, so we have to create it in a
# separate terraform run.

task :_apply_prereqs, [:dir, :tmpdir] do |taskname, args|
  sh "cd #{args[:dir]} && TMPDIR=#{args[:tmpdir]} terragrunt apply-all --terragrunt-non-interactive"
end
CLEAN << "#{@tmpdir_prereqs}/terragrunt"

task :_destroy_prereqs, [:dir, :tmpdir] do |taskname, args|
  sh "cd #{args[:dir]} && TMPDIR=#{args[:tmpdir]} terragrunt destroy-all --terragrunt-non-interactive"
end

DEFAULT_PREREQS_DIR = "../prereqs/#{ENV["RAKE_ENV_SHORT"]}"

desc "[ADVANCED] Change the EBS Volume used by a component (couchdb, prometheus), e.g after restoring from a Snapshot"
task :import_volume, [:component, :new_volumd_id, :availability_zone] do |taskname, args|
  unless args[:component]
    raise "Argument :component is required."
  end
  unless args[:new_volumd_id]
    raise "Argument :new_volume_id is required."
  end
  unless args[:availability_zone]
    raise "Argument :availability_zone is required."
  end
  sh "cd #{DEFAULT_PREREQS_DIR}/volume && TMPDIR=#{@tmpdir_prereqs} \
    terragrunt state rm aws_ebs_volume.#{args[:component]}_#{args[:availability_zone]}"
  sh "cd #{DEFAULT_PREREQS_DIR}/volume && TMPDIR=#{@tmpdir_prereqs} \
    terragrunt import aws_ebs_volume.#{args[:component]}_#{args[:availability_zone]} #{args[:new_volumd_id]}"
end
