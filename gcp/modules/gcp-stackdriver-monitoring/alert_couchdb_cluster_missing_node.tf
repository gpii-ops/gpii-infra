resource "google_monitoring_alert_policy" "couchdb_missing_node" {
  display_name = "CouchDB nodes are visible by the cluster"
  combiner     = "OR"

  conditions {
    condition_threshold {
      filter          = "metric.type=\"logging.googleapis.com/user/couchdb_missing_node.error\" resource.type=\"k8s_container\""
      comparison      = "COMPARISON_GT"
      threshold_value = 0
      duration        = "600s"

      aggregations {
        alignment_period   = "60s"
        per_series_aligner = "ALIGN_SUM"
      }

      denominator_filter = ""
    }

    display_name = "CouchDB node is missing in the cluster"
  }

  documentation = {
    content   = "[Use this link to explore policy events in Logs Viewer](https://console.cloud.google.com/logs/viewer?project=${var.project_id}&organizationId=247149361674&supportedpurview=project&minLogLevel=0&expandAll=false&limitCustomFacetWidth=true&advancedFilter=resource.type%3D%22k8s_container%22%20AND%20resource.labels.project_id%3D%22${var.project_id}%22%20AND%20resource.labels.cluster_name%3D%22k8s-cluster%22%20AND%20resource.labels.namespace_name%3D%22gpii%22%20AND%20labels.k8s-pod%2Fapp%3D%22couchdb%22%20AND%20labels.k8s-pod%2Frelease%3D%22couchdb%22%20AND%20resource.labels.container_name%3D%22couchdb-statefulset-assembler%22%20AND%20textPayload:%20%22%20couchdb%20node%20in%20the%20cluster:%22)"
    mime_type = "text/markdown"
  }

  notification_channels = ["${google_monitoring_notification_channel.email.name}", "${google_monitoring_notification_channel.alerts_slack.*.name}"]
  enabled               = "true"

  depends_on = ["google_logging_metric.couchdb_missing_node"]
}
