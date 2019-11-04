resource "google_logging_metric" "couchdb_membership_error" {
  depends_on = ["null_resource.destroy_old_stackdriver_resources"]
  name       = "couchdb_membership.error"
  filter     = "resource.type=\"k8s_container\" AND resource.labels.container_name=\"couchdb-statefulset-assembler\" AND severity>=\"ERROR\""

  metric_descriptor {
    metric_kind = "DELTA"
    value_type  = "INT64"
  }
}
