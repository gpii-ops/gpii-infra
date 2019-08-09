require "rake/clean"

import "/rakefiles/xk_config.rake"
import "/rakefiles/xk_infra.rake"
import "/rakefiles/xk_util.rake"

require_relative "./secrets.rb"
require_relative "./sh_filter.rb"

@exekube_cmd = "/usr/local/bin/xk"

# This task is being called from entrypoint.rake and runs inside exekube container.
# It applies secret-mgmt, sets secrets, and then executes arbitrary command from args[:cmd].
# You should not invoke this task directly!
task :xk, [:cmd, :skip_secret_mgmt, :preserve_stderr, :sync_gke_istio_state] => [:configure, :configure_secrets] do |taskname, args|
  sh "#{@exekube_cmd} up live/#{@env}/secret-mgmt" unless args[:skip_secret_mgmt] == "true"

  Rake::Task["set_secrets"].invoke

  Rake::Task["sync_gke_istio_state"].invoke if args[:sync_gke_istio_state] == "true"

  sh_filter "#{@exekube_cmd} #{args[:cmd]}", args[:preserve_stderr] == "true" if args[:cmd]
end

# vim: et ts=2 sw=2:
