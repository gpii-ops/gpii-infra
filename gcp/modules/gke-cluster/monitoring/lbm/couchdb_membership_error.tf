resource "google_logging_metric" "couchdb_membership_error" {
  name   = "couchdb_membership.error"
  filter = "resource.type=\"k8s_container\" AND resource.labels.container_name=\"couchdb-statefulset-assembler\" AND severity>=\"ERROR\""
}
