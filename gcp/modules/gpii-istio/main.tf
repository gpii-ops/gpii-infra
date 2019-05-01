terraform {
  backend "gcs" {}
}

resource "kubernetes_namespace" "gpii" {
  metadata {
    name = "gpii"

    labels {
      istio-injection = "enabled"
    }
  }
}
