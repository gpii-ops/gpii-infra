terraform {
  backend "gcs" {}
}

variable "project_id" {}
variable "serviceaccount_key" {}
variable "infra_region" {}
variable "nonce" {}

provider "google" {
  project     = "${var.project_id}"
  credentials = "${var.serviceaccount_key}"
}

# This resource waits till GCP allocates IP address for Istio ingress gateway
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

resource "google_compute_address" "istio-ingress" {
  project      = "${var.project_id}"
  region       = "${var.infra_region}"
  name         = "istio-ingress"
  address_type = "EXTERNAL"
  address      = "${data.kubernetes_service.istio-ingressgateway.load_balancer_ingress.0.ip}"
  network_tier = "PREMIUM"
}
