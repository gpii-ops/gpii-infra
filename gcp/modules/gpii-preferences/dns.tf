data "kubernetes_service" "istio-ingressgateway" {
  metadata {
    name      = "istio-ingressgateway"
    namespace = "istio-system"
  }
}

resource "google_dns_record_set" "preferences-dns" {
  name         = "preferences.${var.domain_name}."
  project      = "${var.project_id}"
  managed_zone = "${replace(var.domain_name, ".", "-")}"

  type    = "A"
  ttl     = 300
  rrdatas = ["${data.kubernetes_service.istio-ingressgateway.load_balancer_ingress.0.ip}"]
}
