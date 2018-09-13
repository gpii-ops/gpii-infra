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
exclusion_name = "calico-typha-health-summary-ok"
exclusion_description = "calico typha 'Overall health summary' that looks ok"
# TODO: Better (multi-line) string formatting
# TODO: How to get project name into logName? Use ":/logs/kubelet" instead of exact match? Old version: 'logName=projects/gpii-gcp-dev-tyler/logs/kubelet'
# NOTE: Trailing space on ' 200 ' is important!
exclusion_filter = "resource.type=container AND logName:/logs/calico-typha AND textPayload:\"Overall health summary=&health.HealthReport{Live:true, Ready:true}\""
