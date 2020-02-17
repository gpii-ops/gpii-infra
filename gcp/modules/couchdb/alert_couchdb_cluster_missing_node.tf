resource "google_monitoring_alert_policy" "couchdb_missing_node" {
  depends_on = [
    "module.couchdb",
    "null_resource.couchdb_enable_pv_backups",
    "null_resource.couchdb_finish_cluster",
    "null_resource.wait_for_lbms",
  ]

  display_name = "CouchDB nodes are visible by the cluster"
  combiner     = "OR"
  project      = "${var.project_id}"

  conditions = [
    {
      condition_threshold {
        filter          = "metric.type=\"logging.googleapis.com/user/${google_logging_metric.couchdb_missing_node.name}\" resource.type=\"k8s_container\""
        comparison      = "COMPARISON_GT"
        threshold_value = "1.0"
        duration        = "600s"

        aggregations {
          alignment_period     = "60s"
          per_series_aligner   = "ALIGN_SUM"
          cross_series_reducer = "REDUCE_COUNT"

          group_by_fields = [
            "resource.label.pod_name",
          ]
        }

        trigger {
          count = "1"
        }
      }

      display_name = "More than one CouchDB node is missing for some CouchDB nodes"
    },
    {
      condition_threshold {
        filter          = "metric.type=\"logging.googleapis.com/user/${google_logging_metric.couchdb_missing_node.name}\" resource.type=\"k8s_container\""
        comparison      = "COMPARISON_GT"
        threshold_value = 0
        duration        = "600s"

        aggregations {
          alignment_period   = "60s"
          per_series_aligner = "ALIGN_SUM"
        }

        denominator_filter = ""
      }

      display_name = "CouchDB node is missing in the cluster for more than 10 minutes"
    },
  ]

  documentation = {
    content   = "[Use this link to explore policy events in Logs Viewer](https://console.cloud.google.com/logs/viewer?project=${var.project_id}&organizationId=247149361674&supportedpurview=project&minLogLevel=0&expandAll=false&limitCustomFacetWidth=true&advancedFilter=resource.type%3D%22k8s_container%22%20AND%20resource.labels.project_id%3D%22${var.project_id}%22%20AND%20resource.labels.cluster_name%3D%22k8s-cluster%22%20AND%20resource.labels.namespace_name%3D%22gpii%22%20AND%20labels.k8s-pod%2Fapp%3D%22couchdb%22%20AND%20labels.k8s-pod%2Frelease%3D%22couchdb%22%20AND%20resource.labels.container_name%3D%22couchdb-statefulset-assembler%22%20AND%20textPayload:%20%22%20couchdb%20node%20in%20the%20cluster:%22)"
    mime_type = "text/markdown"
  }

  notification_channels = ["${data.terraform_remote_state.alert_notification_channel.slack_notification_channel}", "${data.terraform_remote_state.alert_notification_channel.mail_notification_channel}"]
  enabled               = "true"
}
