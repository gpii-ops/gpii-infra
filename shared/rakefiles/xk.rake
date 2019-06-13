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

  sh_filter "sh -c '
    # retrieve TF state
    RESOURCES=\"$(terragrunt state pull --terragrunt-working-dir \"live/#{@env}/k8s/istio\" | jq -er \".modules[].resources\")\"
    [ \"$?\" -ne 0 ] && exit 1

    for HPA in istio-egressgateway istio-ingressgateway istio-pilot istio-policy istio-telemetry; do
      echo \"${RESOURCES}\" | jq -er \".[\\\"kubernetes_horizontal_pod_autoscaler.${HPA}\\\"]\" >/dev/null
      if [ \"$?\" -ne 0 ]; then
        # and if hpa exists
        kubectl get hpa istio-egressgateway -n istio-system --request-timeout=\"5s\"
        if [ \"$?\" -eq 0 ]; then
          # import it to TF state
          terragrunt import \"kubernetes_horizontal_pod_autoscaler.${HPA}\" \"istio-system/${HPA}\" --terragrunt-working-dir \"live/#{@env}/k8s/istio\"
        fi
      fi
    done'"

  sh_filter "#{@exekube_cmd} #{args[:cmd]}", !args[:preserve_stderr].nil? if args[:cmd]
end

# vim: et ts=2 sw=2:
