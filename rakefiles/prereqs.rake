# We need a DNS zone before kops will do anything, so we have to create it in a
# separate terraform run.

task :_apply_prereqs, [:dir, :tmpdir] do |taskname, args|
  sh "cd #{args[:dir]} && TMPDIR=#{args[:tmpdir]} terragrunt apply-all --terragrunt-non-interactive"
end
CLEAN << "#{@tmpdir_prereqs}/terragrunt"

task :_destroy_prereqs, [:dir, :tmpdir] do |taskname, args|
  sh "cd #{args[:dir]} && TMPDIR=#{args[:tmpdir]} terragrunt destroy-all --terragrunt-non-interactive"
end
