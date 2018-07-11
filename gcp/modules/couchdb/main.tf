terraform {
  backend "gcs" {}
}

variable "couchdb_prd_replicas" {
  default = 3
}

variable "couchdb_dev_replicas" {
  default = 2
}

variable "release_namespace" {
  default = "gpii"
}

variable "env" {}
variable "secrets_dir" {}
variable "values_dir" {}
variable "project_id" {}
variable "serviceaccount_key" {}

provider "google" {
  project     = "${var.project_id}"
  credentials = "${var.serviceaccount_key}"
}

resource "google_compute_disk" "couchdb" {
  count = "${var.env == "dev" ? var.couchdb_dev_replicas : var.couchdb_prd_replicas}"
  name  = "couchdb-${count.index}"
  type  = "pd-ssd"
  size  = 10
  zone  = "us-central1-a"
}

data "template_file" "couchdb_pvs" {
  template = "${file("resources/pv.yaml")}"
  count    = "${var.env == "dev" ? var.couchdb_dev_replicas : var.couchdb_prd_replicas}"

  vars {
    env   = "${var.env}"
    index = "${count.index}"
  }
}

resource "null_resource" "couchdb_pvs" {
  depends_on = ["google_compute_disk.couchdb"]

  provisioner "local-exec" {
    command = <<EOF
      echo "${join("", data.template_file.couchdb_pvs.*.rendered)}" | kubectl create -f -
    EOF
  }

  provisioner "local-exec" {
    when    = "destroy"
    command = <<EOF
      sleep 30 # Since there is no way to establish a proper dependency for module, we need to give couchdb helm release time to uninstall
      echo "${join("", data.template_file.couchdb_pvs.*.rendered)}" | kubectl delete --ignore-not-found -f -
    EOF
  }

}

module "couchdb" {
  source           = "/exekube-modules/helm-release"
  tiller_namespace = "kube-system"
  client_auth      = "${var.secrets_dir}/kube-system/helm-tls"

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
          curl -s http://${var.couchdb_admin_username}:${var.couchdb_admin_password}@127.0.0.1:5984/_cluster_setup \
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
