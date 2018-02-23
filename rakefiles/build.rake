require "rake/clean"
require_relative "./dns_lookup.rb"
import "../rakefiles/kops.rake"
import "../rakefiles/prereqs.rake"
require_relative "./terraform_output.rb"
require_relative "./wait_for.rb"

PREREQS_DIR = "../prereqs/#{ENV["RAKE_ENV_SHORT"]}"

desc "Create or update cluster prereqs (e.g DNS for cluster)"
task :apply_prereqs => @tmpdir_prereqs do
  Rake::Task["_apply_prereqs"].invoke(PREREQS_DIR, @tmpdir_prereqs)
end

desc "Destroy cluster prereqs (e.g DNS for cluster)"
task :destroy_prereqs => @tmpdir_prereqs do
  Rake::Task["_destroy_prereqs"].invoke(PREREQS_DIR, @tmpdir_prereqs)
end

task :setup_prereqs_output => :apply_prereqs do
  @prereqs_output = terraform_output(PREREQS_DIR, @tmpdir_prereqs)
end

RAKEFILES = FileList.new("../modules/**/Rakefile")

desc "Run each module's :generate task"
task :generate_modules => [@tmpdir, :apply_prereqs] do
  RAKEFILES.each do |rakefile|
    sh "cd #{File.dirname(rakefile)} && rake generate"
  end
end

desc "[ADVANCED] Delete a Terraform lock; use if you encounter 'Error acquiring the state lock'"
task :force_unlock, [:id, :path] => @tmpdir do |taskname, args|
  puts "NOTE: You must run `rake generate_modules` before running this task."
  puts "I can't do it for you because it prevents me from deleting locks in prereqs, which are a prereq of running `rake generate_modules`."
  puts "(Sorry about that.)"
  unless args[:id]
    raise "Argument :id is required. Get it from the error message ('Failed to unlock state')."
  end
  unless args[:path]
    raise "Argument :path is required. Get it from the error message ('Failed to unlock state')."
  end

  # The goal is to reverse engineer the path in the repo from the path to the
  # lock.
  path_to_component = args[:path].dup
  path_to_component.gsub!(%r{^gpii-terraform-state/}, "../")
  path_to_component.gsub!(%r{/dev-[^/]+/}, "/dev/")
  path_to_component.gsub!(%r{/terraform.tfstate$}, "")
  puts "Calculated path_to_component '#{path_to_component}' from path '#{args[:path]}'."
  sh "cd #{path_to_component} && terragrunt force-unlock -force #{args[:id]}"
end

task :find_zone_id => :setup_prereqs_output do
  @zone_id = @prereqs_output["cluster_dns_zone_id"]["value"]
end

task :wait_for_dns, [:hostname] => :find_zone_id do |taskname, args|
  # I tried to do the filtering in the aws cli with:
  #
  # --max-items 1 --query\"ResourceRecordSets[?Name == '#{args[:hostname]}.']\"
  #
  # but I couldn't get it to work.
  wait_for("aws route53 list-resource-record-sets \
    --hosted-zone-id '#{@zone_id}' \
    | grep -q '#{args[:hostname]}' \
  ")
end

@api_hostname = "api.#{ENV['TF_VAR_cluster_name']}"

desc "Wait until cluster has converged enough to create DNS records for API servers"
task :wait_for_api_dns do
  puts "We must wait for:"
  puts "- the API server to come up and report itself to dns-controller"
  puts "- dns-controller to create api.* A records"
  puts "(More info: https://github.com/kubernetes/kops/blob/master/docs/boot-sequence.md)"
  puts
  puts "It usually takes about 3 minutes for the cluster to converge and DNS records to appear."
  puts
  puts "Waiting for DNS records for #{@api_hostname} to exist..."
  puts "(You can Ctrl-C out of this safely. You may need to run :destroy afterward.)"
  Rake::Task["wait_for_dns"].invoke(@api_hostname)
end

desc "Wait until DNS records for API servers are available locally"
task :wait_for_api_dns_local do
  # A DNS lookup miss is pretty expensive -- many resolvers seem to cache
  # NXDOMAIN for ten minutes. This is why :wait_for_api_dns watches Route 53
  # directly: to avoid an early lookup producing a long-lived lookup miss.
  #
  # However, a lot of stuff will fail unless we can actually resolve those DNS
  # records locally. Since awkward failures are worse than long delays, we wait
  # for the local resolver to catch up to Route 53.
  puts "If we look up api.* records too early, local DNS may cache the negative lookup and things will break."
  puts "On my home internet, behind an AirPort, it takes 10 minutes for the bad result to clear and things to work again."
  puts
  puts "Waiting for DNS records for #{@api_hostname} to be resolvable locally..."
  puts "(You can Ctrl-C out of this safely. You may need to run :destroy afterward.)"
  wait_for(@api_hostname, run_with: method(:dns_lookup))
end

desc "Display admin password for cluster"
task :display_admin_password do
  sh "cd ../modules/k8s && rake display_admin_password"
end

desc "[ADVANCED] Delete kops state for this cluster; will make an existing cluster unusable without S3 rollback"
task :kops_delete_cluster do
  sh "cd ../modules/k8s && rake kops_delete_cluster"
end

desc "Run each module's :clean task"
task :clean_modules do
  RAKEFILES.each do |rakefile|
    sh "cd #{File.dirname(rakefile)} && rake clean"
  end
end
Rake::Task["clean"].enhance do
    Rake::Task["clean_modules"].invoke
end

desc "Run each module's :clobber task"
task :clobber_modules do
  RAKEFILES.each do |rakefile|
    sh "cd #{File.dirname(rakefile)} && rake clobber"
  end
end
Rake::Task["clobber"].enhance do
    Rake::Task["clobber_modules"].invoke
end


# vim: ts=2 sw=2:
