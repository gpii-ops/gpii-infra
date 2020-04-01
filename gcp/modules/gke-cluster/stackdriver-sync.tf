# GKE Stackdriver state needs to be synced right after the cluster is created
# for the firs time and before istio module runs

resource "null_resource" "sync_gke_stackdriver_state" {
  depends_on = ["module.gke_cluster"]

  provisioner "local-exec" {
    command     = "/rakefiles/scripts/sync_gke_stackdriver_state.sh"
    working_dir = "/project"

    environment = {
      ENV = "${var.env}"
    }
  }
}
