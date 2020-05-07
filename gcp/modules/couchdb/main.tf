terraform {
  backend "gcs" {}
}

provider "google" {
  project     = "${var.project_id}"
  credentials = "${var.serviceaccount_key}"
}

variable "env" {}
variable "project_id" {}
variable "serviceaccount_key" {}
variable "secrets_dir" {}
variable "charts_dir" {}
variable "nonce" {}
variable "couchdb_helper_repository" {}
variable "couchdb_helper_checksum" {}
variable "couchdb_init_repository" {}
variable "couchdb_init_checksum" {}
variable "couchdb_repository" {}
variable "couchdb_checksum" {}

# Terragrunt variables

variable "backup_deltas" {}
variable "release_namespace" {}
variable "requests_cpu" {}
variable "requests_memory" {}
variable "limits_cpu" {}
variable "limits_memory" {}
variable "pv_capacity" {}
variable "pv_reclaim_policy" {}
variable "pv_storage_class" {}
variable "pv_provisioner" {}
variable "execute_destroy_pvcs" {}
variable "execute_recover_pvcs" {}

# Secret variables

variable "secret_couchdb_admin_password" {}
variable "secret_couchdb_admin_username" {}
variable "secret_couchdb_auth_cookie" {}
variable "key_tfstate_encryption_key" {}
variable "uuid_morphic_client_id" {}
variable "uuid_morphic_client_secret" {}

# Default variables

variable "replica_count" {
  default = 3
}

data "template_file" "couchdb_values" {
  depends_on = ["null_resource.couchdb_recover_pvcs"]
  template   = "${file("values.yaml")}"

  vars {
    couchdb_admin_username    = "${var.secret_couchdb_admin_username}"
    couchdb_admin_password    = "${var.secret_couchdb_admin_password}"
    couchdb_auth_cookie       = "${var.secret_couchdb_auth_cookie}"
    couchdb_helper_repository = "${var.couchdb_helper_repository}"
    couchdb_helper_sha        = "${var.couchdb_helper_checksum}"
    couchdb_init_repository   = "${var.couchdb_init_repository}"
    couchdb_init_sha          = "${var.couchdb_init_checksum}"
    couchdb_repository        = "${var.couchdb_repository}"
    couchdb_sha               = "${var.couchdb_checksum}"
    replica_count             = "${var.replica_count}"
    requests_cpu              = "${var.requests_cpu}"
    requests_memory           = "${var.requests_memory}"
    limits_cpu                = "${var.limits_cpu}"
    limits_memory             = "${var.limits_memory}"
    pv_capacity               = "${var.pv_capacity}"
    pv_storage_class          = "${var.pv_storage_class}"
    pv_provisioner            = "${var.pv_provisioner}"
  }
}

data "template_file" "morphic_credentials" {
  template = "${file("morphic_credentials.json")}"

  vars {
    morphic_client_id     = "${var.uuid_morphic_client_id}"
    morphic_client_secret = "${var.uuid_morphic_client_secret}"
    timestamp             = "${timestamp()}"
  }
}

module "couchdb" {
  source           = "/exekube-modules/helm-release"
  tiller_namespace = "kube-system"
  client_auth      = "${var.secrets_dir}/kube-system/helm-tls"

  release_name            = "couchdb"
  release_namespace       = "${var.release_namespace}"
  release_values          = ""
  release_values_rendered = "${data.template_file.couchdb_values.rendered}"

  chart_name = "${var.charts_dir}/couchdb"
}

resource "null_resource" "couchdb_finish_cluster" {
  depends_on = ["module.couchdb"]

  triggers = {
    nonce = "${var.nonce}"
  }

  provisioner "local-exec" {
    command = <<EOF
      COUCHDB_URL="http://${var.secret_couchdb_admin_username}:${var.secret_couchdb_admin_password}@127.0.0.1:5984"
      PORT_FORWARD_CMD="kubectl -n ${var.release_namespace} port-forward statefulset/couchdb-couchdb 5984:5984"

      start_forwarding_port() {
        sleep_secs=5
        echo "...starting port forward (and sleeping $sleep_secs)..."
        $PORT_FORWARD_CMD </dev/null &>/dev/null &
        sleep $sleep_secs
      }

      stop_forwarding_port() {
        sleep_secs=1
        echo "...stopping port forward (and sleeping $sleep_secs)..."
        kill $(pgrep -f "^$PORT_FORWARD_CMD")
        sleep $sleep_secs
      }

      RETRIES=15
      RETRY_COUNT=1
      while [ "$CLUSTER_READY" != "true" ]; do
        echo "[Try $RETRY_COUNT of $RETRIES] Waiting for all CouchDB pods to join the cluster..."
        stop_forwarding_port
        start_forwarding_port
        MEMBERSHIP_OUTPUT=$(curl -s $COUCHDB_URL/_membership 2>/dev/null)
        CLUSTER_MEMBERS_COUNT=$(echo $MEMBERSHIP_OUTPUT | jq -r .cluster_nodes[] | grep -c .)
        echo "/_membership returned:"
        echo "$MEMBERSHIP_OUTPUT" | jq
        echo "$CLUSTER_MEMBERS_COUNT of ${var.replica_count} pods have joined the cluster."
        if [ "$CLUSTER_MEMBERS_COUNT" == "${var.replica_count}" ]; then
          CLUSTER_READY="true"
        fi
        if [ "$RETRY_COUNT" == "$RETRIES" ] && [ "$CLUSTER_READY" != "true" ]; then
          echo "Retry limit reached, giving up!"
          stop_forwarding_port
          exit 1
        fi
        if [ "$CLUSTER_READY" != "true" ]; then
          sleep 10
        fi
        RETRY_COUNT=$(($RETRY_COUNT+1))
      done

      RETRY_COUNT=1
      while [ "$STATUS" != '"Cluster is already finished"' ]; do
        echo "[Try $RETRY_COUNT of $RETRIES] Posting \"finish_cluster\"..."
        stop_forwarding_port
        start_forwarding_port
        RESULT=$(
          curl -s $COUCHDB_URL/_cluster_setup \
          -X POST -H 'Content-Type: application/json' -d '{"action": "finish_cluster"}')
        echo "_cluster_setup returned:"
        echo "$RESULT" | jq
        STATUS=$(echo $RESULT | jq ".reason")
        if [ "$RETRY_COUNT" == "$RETRIES" ] && [ "$STATUS" != '"Cluster is already finished"' ]; then
          echo "Retry limit reached, giving up!"
          stop_forwarding_port
          exit 1
        fi
        if [ "$STATUS" != '"Cluster is already finished"' ]; then
          sleep 10
        else
          echo "Trying to create ${var.release_namespace} DB..."
          curl -s -X PUT $COUCHDB_URL/${var.release_namespace} || true
          echo "Trying to load default morphic credentials into ${var.release_namespace} DB..."
          echo '${data.template_file.morphic_credentials.rendered}' | curl -s -d @- \
            -H "Content-type: application/json" \
            -X POST $COUCHDB_URL/${var.release_namespace}/_bulk_docs || true
        fi
        RETRY_COUNT=$(($RETRY_COUNT+1))
      done

      stop_forwarding_port
    EOF
  }
}

resource "null_resource" "couchdb_enable_pv_backups" {
  depends_on = ["module.couchdb"]

  triggers = {
    nonce = "${var.nonce}"
  }

  provisioner "local-exec" {
    command = <<EOF
      # We want to get all PVs claimed by CouchDB, all of them got unique names with database-storage-couchdb as common part.
      # To apply this condition in JSONPath filter we need either regexp match (=~) or string function (substring, i.e. startsWith).
      # None of these available in kubectl jsonpath implementation (https://github.com/kubernetes/kubernetes/issues/61406)
      # So we have to rely on jq for filtering
      for PV in $(kubectl get pv -o json | jq --raw-output '.items[] | select(.spec.claimRef.name | startswith("database-storage-couchdb")) | .metadata.name'); do
        # We need this check, because kubectl exits with non-zero code, when there is no changes:
        # https://github.com/kubernetes/kubernetes/issues/58212
        if [ "$(kubectl get pv $PV -o jsonpath="{.metadata.annotations.backup\.kubernetes\.io/deltas}")" != "${var.backup_deltas}" ]; then
          kubectl patch pv $PV -p '{"metadata": {"annotations": {"backup.kubernetes.io/deltas": "${var.backup_deltas}"}}}'
        fi
      done
    EOF
  }
}

resource "null_resource" "couchdb_destroy_pvcs" {
  count = "${var.execute_destroy_pvcs == "true" ? 1 : 0}"

  provisioner "local-exec" {
    when = "destroy"

    command = <<EOF
      for PVC in $(kubectl get pvc -n ${var.release_namespace} -o json | jq -r '.items[] | select(.metadata.name | startswith("database-storage-couchdb")) | .metadata.name'); do
        timeout -t 600 kubectl -n ${var.release_namespace} delete --ignore-not-found --grace-period=300 pvc $PVC
      done
    EOF
  }
}

data "terraform_remote_state" "alert_notification_channel" {
  backend = "gcs"

  config {
    credentials    = "${var.serviceaccount_key}"
    bucket         = "${var.project_id}-tfstate"
    prefix         = "${var.env}/k8s/stackdriver/monitoring"
    encryption_key = "${var.key_tfstate_encryption_key}"
  }
}

resource "null_resource" "wait_for_lbms" {
  depends_on = ["google_logging_metric.couchdb_missing_node"]

  triggers = {
    nonce = "${var.nonce}"
  }

  provisioner "local-exec" {
    command = <<EOF
      MAX_RETRIES=60
      SLEEP_SEC=5
      for RESOURCE in ${google_logging_metric.couchdb_missing_node.name}; do
        ALERT_READY=false
        COUNT=1
        while [ "$ALERT_READY" != 'true' ] && [ "$COUNT" -le "$MAX_RETRIES" ]; do
          echo "Waiting for log based metric $RESOURCE to be ready ($COUNT/$MAX_RETRIES)"
          gcloud logging metrics describe $RESOURCE > /dev/null
          [ "$?" -eq 0 ] && ALERT_READY=true
          # Sleep only if we're not ready
          [ "$ALERT_READY" != 'true' ] && sleep "$SLEEP_SEC"
          COUNT=$((COUNT+1))
        done
      done
    EOF
  }
}
