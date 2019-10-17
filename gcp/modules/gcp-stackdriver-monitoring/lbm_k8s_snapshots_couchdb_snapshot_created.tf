resource "google_logging_metric" "k8s_snapshots_couchdb_snapshot_created" {
  depends_on = ["null_resource.destroy_old_stackdriver_resources"]
  name       = "k8s_snapshots.couchdb.snapshot_created"
  filter     = "resource.type=\"k8s_container\" AND resource.labels.container_name=\"k8s-snapshots\" AND textPayload:\"snapshot.created\" AND textPayload:\"snapshot_name='pv-database-storage-couchdb\""

  metric_descriptor {
    metric_kind = "DELTA"
    value_type  = "INT64"
  }
}
