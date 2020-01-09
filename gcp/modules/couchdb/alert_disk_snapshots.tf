locals {
  pv_name_regexp = "^pv-database-storage-couchdb-couchdb-[0-9]+$"
}

resource "google_monitoring_alert_policy" "disk_snapshots" {
  depends_on = ["null_resource.wait_for_k8s_snapshots_lbm"]

  display_name = "Snapshots are being created for all persistent volumes"
  combiner     = "OR"
  project      = "${var.project_id}"

  conditions = [
    {
      condition_absent {
        filter   = "metric.type=\"logging.googleapis.com/user/compute.disks.createSnapshot\" resource.type=\"gce_disk\" AND metric.label.pv_name=monitoring.regex.full_match(\"${local.pv_name_regexp}\") AND metric.label.severity=\"NOTICE\""
        duration = "600s"

        aggregations {
          alignment_period     = "300s"
          per_series_aligner   = "ALIGN_SUM"
          cross_series_reducer = "REDUCE_SUM"

          group_by_fields = [
            "metric.label.pv_name",
          ]
        }
      }

      display_name = "Snapshot creation events are missing for some persistent volumes"
    },
    {
      condition_threshold {
        filter = "metric.type=\"logging.googleapis.com/user/compute.disks.createSnapshot\" resource.type=\"gce_disk\" AND metric.label.pv_name=monitoring.regex.full_match(\"${local.pv_name_regexp}\") AND metric.label.severity=\"NOTICE\""

        comparison      = "COMPARISON_LT"
        threshold_value = 1.0
        duration        = "600s"

        aggregations {
          alignment_period     = "300s"
          per_series_aligner   = "ALIGN_SUM"
          cross_series_reducer = "REDUCE_SUM"

          group_by_fields = [
            "metric.label.pv_name",
          ]
        }
      }

      display_name = "Snapshot creation events are occurring too infrequently for some persistent volumes"
    },
  ]

  notification_channels = ["${data.terraform_remote_state.alert_notification_channel.slack_notification_channel}", "${data.terraform_remote_state.alert_notification_channel.mail_notification_channel}"]
  user_labels           = {}
  enabled               = "true"
}

resource "null_resource" "wait_for_k8s_snapshots_lbm" {
  depends_on = ["google_logging_metric.disks_createsnapshot"]

  triggers = {
    nonce = "${var.nonce}"
  }

  provisioner "local-exec" {
    command = <<EOF
      COUNT=1
      MAX_RETRIES=60
      SLEEP_SEC=5
      ALERT_READY=false

      while [ "$ALERT_READY" != 'true' ] && [ "$COUNT" -le "$MAX_RETRIES" ]; do
        echo "Waiting for log based metric compute.disks.createSnapshot to be ready ($COUNT/$MAX_RETRIES)"
        gcloud logging metrics describe compute.disks.createSnapshot > /dev/null
        [ "$?" -eq 0 ] && ALERT_READY=true
        # Sleep only if we're not ready
        [ "$ALERT_READY" != 'true' ] && sleep "$SLEEP_SEC"
        COUNT=$((COUNT+1))
      done
    EOF
  }
}
