resource "kubernetes_network_policy" "deny-default" {
  metadata {
    name      = "deny-default"
    namespace = "${kubernetes_namespace.gpii.metadata.0.name}"
  }

  spec {
    pod_selector {}

    policy_types = ["Ingress", "Egress"]

    egress {
      # Allow egress traffic to Istio control plane
      to {
        namespace_selector {
          match_labels = {
            k8s-app = "istio"
          }
        }
      }

      # Allow egress traffic within namespace
      to {
        namespace_selector {
          match_labels = {
            name = "gpii"
          }
        }
      }

      # Allow egress traffic to dns
      to {
        namespace_selector {
          match_labels = {
            name = "kube-system"
          }
        }

        pod_selector {
          match_labels = {
            k8s-app = "kube-dns"
          }
        }
      }
    }

    egress {
      # Allow egress traffic Compute Metadata
      to {
        ip_block {
          cidr = "10.16.0.0/20"
        }
      }

      ports {
        port     = "8181"
        protocol = "TCP"
      }
    }
  }
}

resource "kubernetes_network_policy" "allow-promsd-to-istio" {
  metadata {
    name      = "allow-promsd-to-istio"
    namespace = "${kubernetes_namespace.gpii.metadata.0.name}"
  }

  spec {
    pod_selector {}

    ingress {
      from {
        namespace_selector {
          match_labels = {
            k8s-app = "istio"
          }
        }

        pod_selector {
          match_labels = {
            app = "promsd"
          }
        }
      }

      ports {
        port     = "http-envoy-prom"
        protocol = "TCP"
      }
    }

    policy_types = ["Ingress"]
  }
}
