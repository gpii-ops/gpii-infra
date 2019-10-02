resource "kubernetes_network_policy" "deny-default" {
  metadata {
    name      = "deny-default"
    namespace = "${kubernetes_namespace.gpii.metadata.0.name}"
  }

  spec {
    pod_selector = {}

    policy_types = ["Ingress"]
  }
}

resource "kubernetes_network_policy" "allow-promsd-to-istio" {
  metadata {
    name      = "allow-promsd-to-istio"
    namespace = "${kubernetes_namespace.gpii.metadata.0.name}"
  }

  spec {
    pod_selector = {}

    ingress = {
      from = {
        namespace_selector = {
          match_labels {
            k8s-app = "istio"
          }
        }

        pod_selector = {
          match_labels {
            app = "promsd"
          }
        }
      }

      ports = {
        port     = "http-envoy-prom"
        protocol = "TCP"
      }
    }

    policy_types = ["Ingress"]
  }
}
