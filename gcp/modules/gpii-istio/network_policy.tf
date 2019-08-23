resource "kubernetes_network_policy" "deny-default" {
  metadata {
    name      = "deny-default"
    namespace = "${kubernetes_namespace.gpii.metadata.0.name}"
  }

  spec {
    pod_selector {}

    policy_types = ["Ingress"]
  }
}
