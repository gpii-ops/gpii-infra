resource "google_logging_metric" "audit_couchdb_snapshot_created" {
  name   = "audit.couchdb.snapshot_created"
  filter = "resource.type=\"gce_snapshot\" AND jsonPayload.event_subtype=\"compute.snapshots.setLabels\" AND jsonPayload.resource.type=\"snapshot\" AND jsonPayload.resource.name: \"pv-database-storage-couchdb\" AND jsonPayload.event_type=\"GCE_OPERATION_DONE\""
  metric_descriptor {
    metric_kind = "DELTA"
    value_type  = "INT64"
  }
}
