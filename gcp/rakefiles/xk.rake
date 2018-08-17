require "rake/clean"

require_relative "./secrets.rb"
require_relative "./sh_filter.rb"

@exekube_cmd = "/usr/local/bin/xk"

desc 'From inside of exekube container: apply infra, secret-mgmt, set secrets, and then execute arbitrary command -- do not call directly!'
task :xk, [:cmd, :skip_infra, :skip_secret_mgmt] do |taskname, args|
  @secrets = Secrets.collect_secrets()

  sh "#{@exekube_cmd} up live/#{@env}/infra" unless args[:skip_infra]
  sh "#{@exekube_cmd} up live/#{@env}/secret-mgmt" unless args[:skip_secret_mgmt]

  Secrets.set_secrets(@secrets)

  sh_filter "#{@exekube_cmd} #{args[:cmd]}" if args[:cmd]
end

# vim: et ts=2 sw=2:
