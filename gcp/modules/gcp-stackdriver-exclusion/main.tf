terraform {
  backend "gcs" {}
}

variable "project_id" {}
variable "serviceaccount_key" {}
variable "exclusions" {
  default = {
    # Calico logs don't always set 'severity' correctly, so instead we match on
    # 'textPayload'.
    "calico-info" = "resource.type=k8s_container AND resource.labels.container_name=(calico-node OR calico-typha) AND textPayload:\"[INFO]\""

    "kubelet-discovered-runtime-cgroups" = "resource.type=k8s_node AND logName=projects/__var.project_id__/logs/kubelet AND jsonPayload.MESSAGE:\"Discovered runtime cgroups name: /system.slice/docker.service\""

    "kubelet-healthz-200" = "resource.type=k8s_node AND logName=projects/__var.project_id__/logs/kubelet AND jsonPayload.MESSAGE:GET /healthz AND jsonPayload.MESSAGE:\" 200 \""

    # The trailing space is to differentiate status code 200 ("GET /_up 200 ok
    # 0") from a string that happens to start with 200 ("Setting calico-typha
    # requests["cpu"] = 200m").
    "kubelet-stats-summary-200" = "resource.type=k8s_node AND logName=projects/__var.project_id__/logs/kubelet AND jsonPayload.MESSAGE:GET /stats/summary AND jsonPayload.MESSAGE:\" 200 \""
  }
}

module "gcp_stackdriver_exclusion" {
  source             = "/exekube-modules/gcp-stackdriver-exclusion"
  project_id         = "${var.project_id}"
  serviceaccount_key = "${var.serviceaccount_key}"
  exclusions         = "${var.exclusions}"
}
