terraform {
  backend "gcs" {}
}

resource "kubernetes_config_map" "metadata-agent-config" {
  metadata = {
    name      = "metadata-agent-config"
    namespace = "kube-system"

    labels = {
      # This seems to be a bug with Terraform, object in fact  # has the labels below, but TF does not see them  #  "addonmanager.kubernetes.io/mode" = "EnsureExists",  #  "kubernetes.io/cluster-service"   = "true"
    }
  }

  data = {
    "NannyConfiguration" = "apiVersion: nannyconfig/v1alpha1\nkind: NannyConfiguration\nbaseMemory: 50Mi\nbaseCPU: 80m"
  }
}
