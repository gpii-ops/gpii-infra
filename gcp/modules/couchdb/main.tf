terraform {
  backend "gcs" {}
}

variable "values_dir" {}
variable "release_namespace" {
	default = "gpii"
}

module "couchdb" {
  source = "/exekube-modules/helm-template-release"

  release_name      = "couchdb"
  release_namespace = "${var.release_namespace}"
  release_values    = "${var.values_dir}/couchdb.yaml"

  chart_name = "../../../../../charts/couchdb"
}

variable "couchdb_admin_username" {}
variable "couchdb_admin_password" {}

resource "null_resource" "couchdb_finish_cluster" {
  depends_on = ["module.couchdb"]

  provisioner "local-exec" {
    command = <<EOF
      RETRIES=10
      RETRY_COUNT=1
      while [ "$PODS_READY" != "true" ] && [ "$RETRY_COUNT" -lt "$RETRIES" ]; do
        PODS_READY="true"
        echo "[TRY $RETRY_COUNT] Waiting for all CouchDB pods to become Running..."
        for STATUS in $(kubectl get pods --namespace ${var.release_namespace} -l app=couchdb -o jsonpath='{.items[*].status.phase}'); do
          if [ "$STATUS" != "Running" ]; then
            PODS_READY="false"
          fi
        done
        RETRY_COUNT=$(($RETRY_COUNT+1))
        sleep 10
      done

      if [ "$RETRY_COUNT" -eq "$RETRIES" ] ; then
        echo "Retry limit reached, giving up!"
        exit 1
      fi

      RETRY_COUNT=1
      while [ "$STATUS" != '"Cluster is already finished"' ] && [ "$RETRY_COUNT" -lt "$RETRIES" ]; do
        RESULT=$(
          kubectl exec --namespace ${var.release_namespace} couchdb-couchdb-0 -c couchdb -- \
          curl -s http://${var.couchdb_admin_username}:${var.couchdb_admin_password}@127.0.0.1:5984/_cluster_setup \
          -X POST -H 'Content-Type: application/json' -d '{"action": "finish_cluster"}')
        echo "[TRY $RETRY_COUNT] CouchDB returned: $RESULT"
        STATUS=$(echo $RESULT | jq ".reason")
        RETRY_COUNT=$(($RETRY_COUNT+1))
        sleep 10
      done

      if [ "$RETRY_COUNT" -eq "$RETRIES" ] ; then
        echo "Retry limit reached, giving up!"
        exit 1
      fi
    EOF
  }
}
