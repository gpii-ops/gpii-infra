require "rake/clean"
require_relative "./dns_lookup.rb"
require_relative "./wait_for.rb"

# We need a DNS zone before kops will do anything, so we have to create it in a
# separate terraform run. We use a separate tmpdir so we don't mix up these
# downloaded modules with the main terraform run's downloaded modules.
directory @tmpdir_prereqs
CLOBBER << @tmpdir_prereqs

desc "Create or update cluster prereqs (e.g DNS for cluster)"
task :apply_prereqs => @tmpdir_prereqs do
  sh "cd ../prereqs/#{ENV["RAKE_ENV_SHORT"]}/k8s-cluster-dns && TMPDIR=#{@tmpdir_prereqs} terragrunt apply-all --terragrunt-non-interactive"
end
CLEAN << "#{@tmpdir_prereqs}/terragrunt"

desc "Destroy cluster prereqs (e.g DNS for cluster)"
task :destroy_prereqs => @tmpdir_prereqs do
  sh "cd ../prereqs/#{ENV["RAKE_ENV_SHORT"]}/k8s-cluster-dns && TMPDIR=#{@tmpdir_prereqs} terragrunt destroy-all --terragrunt-non-interactive"
end


RAKEFILES = FileList.new("../modules/**/Rakefile")

desc "Run each module's :generate task"
task :generate_modules => [@tmpdir, :apply_prereqs] do
  RAKEFILES.each do |rakefile|
    sh "cd #{File.dirname(rakefile)} && rake generate"
  end
end

task :find_zone_id do
  # Technically it would be more correct to get this value directly from
  # the Terraform run that created the zone. This is simpler, though.
  @zone_id = `aws route53 list-hosted-zones \
    | jq '.HostedZones[] | select(.Name=="#{ENV["TF_VAR_cluster_name"]}.") | .Id' \
  `
  if @zone_id.empty?
    raise "Could not find route53 zone for cluster #{ENV['TF_VAR_cluster_name']}. Make sure :apply_prereqs has run successfully."
  end
  @zone_id.chomp!
  @zone_id.gsub!(%r{"/hostedzone/(.*)"}, "\\1")

end

# Technically it would be more correct to get the name of the API record
# directly from the Terraform run that created the cluster (there is a
# dedicated output for this, consumed by kitchen-terraform). This is
# simpler, though.
@api_hostname = "api.#{ENV['TF_VAR_cluster_name']}"

desc "Wait until cluster has converged enough to create DNS records for API servers"
task :wait_for_api_dns => :find_zone_id do
  puts "We must wait for:"
  puts "- the API server to come up and report itself to dns-controller"
  puts "- dns-controller to create api.* A records"
  puts "(More info: https://github.com/kubernetes/kops/blob/master/docs/boot-sequence.md)"
  puts
  puts "It usually takes about 3 minutes for the cluster to converge and DNS records to appear."
  puts
  puts "Waiting for DNS records for #{@api_hostname} to exist..."
  puts "(You can Ctrl-C out of this safely. You may need to run :destroy afterward.)"

  # I tried to do the filtering in the aws cli with:
  #
  # --max-items 1 --query\"ResourceRecordSets[?Name == '#{@api_hostname}.']\"
  #
  # but I couldn't get it to work.
  wait_for("aws route53 list-resource-record-sets \
    --hosted-zone-id '#{@zone_id}' \
    | grep -q '#{@api_hostname}' \
  ")
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
  wait_for(@api_hostname, run_with=method(:dns_lookup))
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
