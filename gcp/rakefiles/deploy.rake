require "rake/clean"

require_relative "./secrets.rb"
require_relative "./sh_filter.rb"

@exekube_cmd = "/usr/local/bin/xk"

task :set_secrets, [:skip_secret_mgmt] do |taskname, args|
  @secrets = Secrets.collect_secrets()
  Rake::Task[:apply_secret_mgmt].invoke unless args[:skip_secret_mgmt]
  Secrets.set_secrets(@secrets)
end

task :apply_infra do
  sh_filter "#{@exekube_cmd} up live/#{@env}/infra"
end

task :apply_secret_mgmt do
  sh "#{@exekube_cmd} up live/#{@env}/secret-mgmt"
end

task :deploy => [:apply_infra, :set_secrets] do
  sh_filter "#{@exekube_cmd} up"
end

task :destroy_infra => [:destroy] do
  sh "#{@exekube_cmd} down live/#{@env}/infra"
end

task :destroy => [:set_secrets] do
  sh "#{@exekube_cmd} xk down"
end

# vim: et ts=2 sw=2:
