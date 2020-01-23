resource "google_logging_metric" "couchdb_missing_node" {
  depends_on = [
    "module.couchdb",
    "null_resource.couchdb_enable_pv_backups",
    "null_resource.couchdb_finish_cluster",
  ]

  project = "${var.project_id}"
  name    = "couchdb_missing_node.error"
  filter  = "resource.type=\"k8s_container\" AND resource.labels.project_id=\"${var.project_id}\" AND resource.labels.cluster_name=\"k8s-cluster\" AND resource.labels.namespace_name=\"gpii\" AND labels.k8s-pod/app=\"couchdb\" AND labels.k8s-pod/release=\"couchdb\" AND resource.labels.container_name=\"couchdb-statefulset-assembler\" AND textPayload: \" couchdb node in the cluster:\""

  metric_descriptor {
    metric_kind = "DELTA"
    value_type  = "INT64"

    labels {
      key         = "missing_node"
      value_type  = "STRING"
      description = "Name of the missing node"
    }
  }

  label_extractors = {
    missing_node = "REGEXP_EXTRACT(textPayload, \"couchdb node in the cluster: (\\\\w+-\\\\w+-\\\\d+)\")"
  }
}
