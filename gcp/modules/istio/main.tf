terraform {
  backend "gcs" {}
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
