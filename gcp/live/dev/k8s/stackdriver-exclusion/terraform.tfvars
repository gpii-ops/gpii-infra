# ↓ Module metadata
terragrunt = {
  terraform {
    source = "/project/modules//gcp-stackdriver-exclusion"
  }

  include = {
    path = "${find_in_parent_folders()}"
  }
}

# ↓ Module configuration (empty means all default)
# TODO: How to get project name into logName? Use ":/logs/kubelet" instead of exact match? Old version: 'logName=projects/gpii-gcp-dev-tyler/logs/kubelet'
exclusions = {
  "calico-typha-health-summary-ok" = "resource.type=container AND logName:/logs/calico-typha AND textPayload:\"Overall health summary=&health.HealthReport{Live:true, Ready:true}\""
  "kubelet-healthz-200" = "resource.type=gce_instance AND logName:/logs/kubelet AND jsonPayload.MESSAGE:GET /healthz AND jsonPayload.MESSAGE:\" 200 \""
  "kubelet-stats-summary-200" = "resource.type=gce_instance AND logName:/logs/kubelet AND jsonPayload.MESSAGE:GET /stats/summary AND jsonPayload.MESSAGE:\" 200 \""
}
