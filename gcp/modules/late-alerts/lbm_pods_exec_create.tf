resource "google_logging_metric" "pods_exec_create" {
  name   = "io.k8s.core.v1.pods.exec.create"
  filter = "resource.type=\"k8s_cluster\" AND protoPayload.methodName=\"io.k8s.core.v1.pods.exec.create\""

  metric_descriptor {
    metric_kind = "DELTA"
    value_type  = "INT64"
  }
}
