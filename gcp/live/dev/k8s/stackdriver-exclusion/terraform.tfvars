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
exclusions = {
  "calico-typha-health-summary-ok" = "resource.type=container AND logName=projects/__var.project_id__/logs/calico-typha AND textPayload:\"Overall health summary=&health.HealthReport{Live:true, Ready:true}\""
  "kubelet-discovered-runtime-cgroups" = "resource.type=gce_instance AND logName=projects/__var.project_id__/logs/kubelet AND jsonPayload.MESSAGE:\"Discovered runtime cgroups name: /system.slice/docker.service\""
  "kubelet-healthz-200" = "resource.type=gce_instance AND logName=projects/__var.project_id__/logs/kubelet AND jsonPayload.MESSAGE:GET /healthz AND jsonPayload.MESSAGE:\" 200 \""
  # The trailing space is to differentiate status code 200 ("GET /_up 200 ok
  # 0") from a string that happens to start with 200 ("Setting calico-typha
  # requests["cpu"] = 200m").
  "kubelet-stats-summary-200" = "resource.type=gce_instance AND logName=projects/__var.project_id__/logs/kubelet AND jsonPayload.MESSAGE:GET /stats/summary AND jsonPayload.MESSAGE:\" 200 \""
}
