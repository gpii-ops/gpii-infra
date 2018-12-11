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
task :xk, [:cmd, :skip_secret_mgmt, :preserve_stderr] => [:configure_serviceaccount, :configure_kubectl] do |taskname, args|
  @secrets = Secrets.collect_secrets()

  sh "#{@exekube_cmd} up live/#{@env}/secret-mgmt" unless args[:skip_secret_mgmt]

  Secrets.set_secrets(@secrets)

  # GPII-3568 - This is a temporary "hack", to be removed once all our
  # clusters are migrated to the regional ones.
  sh_filter "cd live/#{@env}/k8s/cluster; terragrunt state list | grep '\.cluster$' \
    && terragrunt state mv module.gke_cluster.google_container_cluster.cluster module.gke_cluster.google_container_cluster.cluster-regional; true"

  sh_filter "#{@exekube_cmd} #{args[:cmd]}", !args[:preserve_stderr].nil? if args[:cmd]
end

# vim: et ts=2 sw=2:
