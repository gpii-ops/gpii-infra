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
task :xk, [:cmd, :skip_secret_mgmt, :preserve_stderr] => [:configure, :configure_secrets] do |taskname, args|
  sh "#{@exekube_cmd} up live/#{@env}/secret-mgmt" unless args[:skip_secret_mgmt]

  Rake::Task["set_secrets"].invoke

  # This is temporary task to handle updates of existing clusters to Istio (GPII-3671)
  sh_filter "sh -c '
    # if there is no kubernetes_namespace resource in TF state
    terragrunt state pull --terragrunt-working-dir \"live/#{@env}/k8s/gpii/istio\" | jq -er \".modules[].resources[\\\"kubernetes_namespace.gpii\\\"]\" >/dev/null
    if [ \"$?\" -ne 0 ]; then

      # and if gpii namespace exists
      kubectl get ns gpii --request-timeout=\"5s\"
      if [ \"$?\" -eq 0 ]; then

        # import it to TF state
        terragrunt import kubernetes_namespace.gpii gpii --terragrunt-working-dir \"live/#{@env}/k8s/gpii/istio\"
      fi
    fi'"

  sh_filter "#{@exekube_cmd} #{args[:cmd]}", !args[:preserve_stderr].nil? if args[:cmd]
end

# vim: et ts=2 sw=2:
