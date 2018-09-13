terraform {
  backend "gcs" {}
}

variable "env" {}
variable "secrets_dir" {}
variable "charts_dir" {}
variable "nonce" {}

# Terragrunt variables
variable "couchdb_replicas" {}

variable "backup_deltas" {}
variable "release_namespace" {}

# Secret variables
variable "secret_couchdb_admin_username" {}
variable "secret_couchdb_admin_password" {}
variable "secret_couchdb_auth_cookie" {}

data "template_file" "couchdb_values" {
  template = "${file("values.yaml")}"

  vars {
    env                    = "${var.env}"
    couchdb_admin_username = "${var.secret_couchdb_admin_username}"
    couchdb_admin_password = "${var.secret_couchdb_admin_password}"
    couchdb_auth_cookie    = "${var.secret_couchdb_auth_cookie}"
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

  provisioner "local-exec" {
    command = <<EOF
      RETRIES=10
      RETRY_COUNT=1
      while [ "$PODS_READY" != "true" ]; do
        PODS_READY="true"
        echo "[Try $RETRY_COUNT of $RETRIES] Waiting for all CouchDB pods to become Running..."
        for STATUS in $(kubectl get pods --namespace ${var.release_namespace} -l app=couchdb -o jsonpath='{.items[*].status.phase}'); do
          if [ "$STATUS" != "Running" ]; then
            PODS_READY="false"
          fi
        done
        RETRY_COUNT=$(($RETRY_COUNT+1))
        if [ "$RETRY_COUNT" -eq "$RETRIES" ] ; then
          echo "Retry limit reached, giving up!"
          exit 1
        fi
        sleep 10
      done

      RETRY_COUNT=1
      while [ "$STATUS" != '"Cluster is already finished"' ]; do
        RESULT=$(
          kubectl exec --namespace ${var.release_namespace} couchdb-couchdb-0 -c couchdb -- \
          curl -s http://${var.secret_couchdb_admin_username}:${var.secret_couchdb_admin_password}@127.0.0.1:5984/_cluster_setup \
          -X POST -H 'Content-Type: application/json' -d '{"action": "finish_cluster"}')
        echo "[Try $RETRY_COUNT of $RETRIES] CouchDB returned: $RESULT"
        STATUS=$(echo $RESULT | jq ".reason")
        RETRY_COUNT=$(($RETRY_COUNT+1))
        if [ "$RETRY_COUNT" -eq "$RETRIES" ] ; then
          echo "Retry limit reached, giving up!"
          exit 1
        fi
        sleep 10
      done
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
  depends_on = ["module.couchdb"]

  provisioner "local-exec" {
    when = "destroy"

    command = <<EOF
      for PVC in $(kubectl get pvc --namespace ${var.release_namespace} -o json | jq --raw-output '.items[] | select(.metadata.name | startswith("database-storage-couchdb")) | .metadata.name'); do
        kubectl --namespace ${var.release_namespace} delete --ignore-not-found pvc $PVC
      done
    EOF
  }
}


resource "null_resource" "couchdb_resources" {
  depends_on = ["module.couchdb"]

  provisioner "local-exec" {
    command = "kubectl apply -f ${path.module}/resources/"
  }

  provisioner "local-exec" {
    when    = "destroy"
    command = "kubectl delete --ignore-not-found -f ${path.module}/resources/"
  }
}
