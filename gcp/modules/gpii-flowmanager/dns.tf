resource "null_resource" "ingress_ip_wait" {
  triggers = {
    nonce = "${var.nonce}"
  }

  provisioner "local-exec" {
    command = <<EOF
      COUNT=1
      MAX_RETRIES=60
      SLEEP_SEC=5
      INGRESS_READY=false

      while [ "$INGRESS_READY" != 'true' ] && [ "$COUNT" -le "$MAX_RETRIES" ]; do
        echo "Waiting for istio-ingressgateway ip ($COUNT/$MAX_RETRIES)"
        kubectl -n istio-system get svc istio-ingressgateway -o json | jq -e '.status.loadBalancer.ingress[0].ip'
        [ "$?" -eq 0 ] && INGRESS_READY=true
        # Sleep only if we're not ready
        [ "$INGRESS_READY" != 'true' ] && sleep "$SLEEP_SEC"
        COUNT=$((COUNT+1))
      done
    EOF
  }
}

data "kubernetes_service" "istio-ingressgateway" {
  metadata {
    name      = "istio-ingressgateway"
    namespace = "istio-system"
  }

  depends_on = ["null_resource.ingress_ip_wait"]
}

resource "google_dns_record_set" "flowmanager-dns" {
  name         = "flowmanager.${var.domain_name}."
  project      = "${var.project_id}"
  managed_zone = "${replace(var.domain_name, ".", "-")}"

  type    = "A"
  ttl     = 300
  rrdatas = ["${data.kubernetes_service.istio-ingressgateway.load_balancer_ingress.0.ip}"]
}
