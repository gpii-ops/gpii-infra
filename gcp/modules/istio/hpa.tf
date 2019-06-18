# Most of the values in this module (such as max_replicas or target_cpu_utilization_percentage)
# come from the default Istio deployment by GKE.
# min_replicas has been increased, compared to the GKE defaults, to provide HA.

resource "kubernetes_horizontal_pod_autoscaler" "istio-egressgateway" {
  metadata = {
    name      = "istio-egressgateway"
    namespace = "istio-system"

    labels = {
      k8s-app = "istio"
    }
  }

  spec {
    max_replicas = 5
    min_replicas = 2

    scale_target_ref {
      kind        = "Deployment"
      name        = "istio-egressgateway"
      api_version = "apps/v1beta1"
    }

    target_cpu_utilization_percentage = 80
  }
}

resource "kubernetes_horizontal_pod_autoscaler" "istio-ingressgateway" {
  metadata = {
    name      = "istio-ingressgateway"
    namespace = "istio-system"

    labels = {
      k8s-app = "istio"
    }
  }

  spec {
    max_replicas = 5
    min_replicas = 3

    scale_target_ref {
      kind        = "Deployment"
      name        = "istio-ingressgateway"
      api_version = "apps/v1beta1"
    }

    target_cpu_utilization_percentage = 80
  }
}

resource "kubernetes_horizontal_pod_autoscaler" "istio-pilot" {
  metadata = {
    name      = "istio-pilot"
    namespace = "istio-system"

    labels = {
      k8s-app = "istio"
    }
  }

  spec {
    max_replicas = 5
    min_replicas = 2

    scale_target_ref {
      kind        = "Deployment"
      name        = "istio-pilot"
      api_version = "apps/v1beta1"
    }

    target_cpu_utilization_percentage = 80
  }
}

resource "kubernetes_horizontal_pod_autoscaler" "istio-policy" {
  metadata = {
    name      = "istio-policy"
    namespace = "istio-system"

    labels = {
      k8s-app = "istio"
    }
  }

  spec {
    max_replicas = 5
    min_replicas = 2

    scale_target_ref {
      kind        = "Deployment"
      name        = "istio-policy"
      api_version = "apps/v1beta1"
    }

    target_cpu_utilization_percentage = 80
  }
}

resource "kubernetes_horizontal_pod_autoscaler" "istio-telemetry" {
  metadata = {
    name      = "istio-telemetry"
    namespace = "istio-system"

    labels = {
      k8s-app = "istio"
    }
  }

  spec {
    max_replicas = 5
    min_replicas = 2

    scale_target_ref {
      kind        = "Deployment"
      name        = "istio-telemetry"
      api_version = "apps/v1beta1"
    }

    target_cpu_utilization_percentage = 80
  }
}
