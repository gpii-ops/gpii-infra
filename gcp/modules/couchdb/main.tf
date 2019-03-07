terraform {
  backend "gcs" {}
}

variable "secrets_dir" {}
variable "charts_dir" {}
variable "nonce" {}

# Terragrunt variables

variable "replica_count" {}
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

data "template_file" "couchdb_values" {
  depends_on = ["null_resource.couchdb_recover_pvcs"]
  template   = "${file("values.yaml")}"

  vars {
    couchdb_admin_username = "${var.secret_couchdb_admin_username}"
    couchdb_admin_password = "${var.secret_couchdb_admin_password}"
    couchdb_auth_cookie    = "${var.secret_couchdb_auth_cookie}"
    replica_count          = "${var.replica_count}"
    requests_cpu           = "${var.requests_cpu}"
    requests_memory        = "${var.requests_memory}"
    limits_cpu             = "${var.limits_cpu}"
    limits_memory          = "${var.limits_memory}"
    pv_capacity            = "${var.pv_capacity}"
    pv_storage_class       = "${var.pv_storage_class}"
    pv_provisioner         = "${var.pv_provisioner}"
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

      $PORT_FORWARD_CMD </dev/null &>/dev/null &
      sleep 5

      RETRIES=15
      RETRY_COUNT=1
      while [ "$CLUSTER_READY" != "true" ]; do
        echo "[Try $RETRY_COUNT of $RETRIES] Waiting for all CouchDB pods to join the cluster..."
        CLUSTER_MEMBERS_COUNT=$(curl -s $COUCHDB_URL/_membership 2>/dev/null | jq -r .cluster_nodes[] | grep -c .)
        echo "$CLUSTER_MEMBERS_COUNT of ${var.replica_count} pods have joined the cluster."
        if [ "$CLUSTER_MEMBERS_COUNT" == "${var.replica_count}" ]; then
          CLUSTER_READY="true"
        fi
        if [ "$RETRY_COUNT" == "$RETRIES" ] && [ "$CLUSTER_READY" != "true" ]; then
          echo "Retry limit reached, giving up!"
          kill $(pgrep -f "^$PORT_FORWARD_CMD")
          exit 1
        fi
        if [ "$CLUSTER_READY" != "true" ]; then
          sleep 10
        fi
        RETRY_COUNT=$(($RETRY_COUNT+1))
      done

      RETRY_COUNT=1
      while [ "$STATUS" != '"Cluster is already finished"' ]; do
        RESULT=$(
          curl -s $COUCHDB_URL/_cluster_setup \
          -X POST -H 'Content-Type: application/json' -d '{"action": "finish_cluster"}')
        echo "[Try $RETRY_COUNT of $RETRIES] Posting \"finish_cluster\", CouchDB returned: $RESULT"
        STATUS=$(echo $RESULT | jq ".reason")
        if [ "$RETRY_COUNT" == "$RETRIES" ] && [ "$STATUS" != '"Cluster is already finished"' ]; then
          echo "Retry limit reached, giving up!"
          kill $(pgrep -f "^$PORT_FORWARD_CMD")
          exit 1
        fi
        if [ "$STATUS" != '"Cluster is already finished"' ]; then
          sleep 10
        fi
        RETRY_COUNT=$(($RETRY_COUNT+1))
      done

      kill $(pgrep -f "^$PORT_FORWARD_CMD")
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
