terraform {
  backend "gcs" {}
}

resource "kubernetes_namespace" "locust" {
  metadata {
    name = "locust"

    labels {
      istio-injection = "enabled"
    }
  }
}
