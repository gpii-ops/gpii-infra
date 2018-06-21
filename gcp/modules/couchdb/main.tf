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
      while [ "$STATUS" != "\"Cluster is already finished\"" ]; do
        RESULT=$(
          kubectl exec --namespace ${var.release_namespace} couchdb-couchdb-0 -c couchdb -- \
          curl -s http://${var.couchdb_admin_username}:${var.couchdb_admin_password}@127.0.0.1:5984/_cluster_setup \
          -X POST -H 'Content-Type: application/json' -d '{"action": "finish_cluster"}');
        echo CouchDB returned: $RESULT;
        STATUS=$(echo $RESULT | jq ".reason");
        sleep 5;
      done
    EOF
  }
}
