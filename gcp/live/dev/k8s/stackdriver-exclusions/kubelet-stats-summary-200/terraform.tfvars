# ↓ Module metadata
terragrunt = {
  terraform {
    source = "/project/modules//gcp-stackdriver-exclusion"
  }

  dependencies {
    paths = [
      "../../cluster",
    ]
  }

  include = {
    path = "${find_in_parent_folders()}"
  }
}

# ↓ Module configuration (empty means all default)
exclusion_name = "kubelet-stats-summary-200"
exclusion_description = "kubelet /stats/summary requests that return status code 200"
# TODO: Better (multi-line) string formatting
# TODO: How to get project name into logName? Use ":/logs/kubelet" instead of exact match? Old version: 'logName=projects/gpii-gcp-dev-tyler/logs/kubelet'
# NOTE: Trailing space on ' 200 ' is important!
exclusion_filter = "resource.type=gce_instance AND logName:/logs/kubelet AND jsonPayload.MESSAGE:GET /stats/summary AND jsonPayload.MESSAGE:\" 200 \""
