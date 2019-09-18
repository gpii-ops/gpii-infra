# This resource waits till GKE creates Istio rule for tracing
resource "null_resource" "istio_tracing_wait" {
  triggers = {
    nonce = "${var.nonce}"
  }

  provisioner "local-exec" {
    command = <<EOF
      COUNT=1
      MAX_RETRIES=60
      SLEEP_SEC=5
      READY=false

      while [ "$READY" != 'true' ] && [ "$COUNT" -le "$MAX_RETRIES" ]; do
        echo "Waiting for stackdriver-tracing-rule rule ($COUNT/$MAX_RETRIES)"
        kubectl -n istio-system get --request-timeout 5s rule stackdriver-tracing-rule 2>/dev/null
        [ "$?" -eq 0 ] && READY=true
        # Sleep only if we're not ready
        [ "$READY" != 'true' ] && sleep "$SLEEP_SEC"
        COUNT=$((COUNT+1))
      done
EOF
  }
}

data "external" "istio_tracing" {
  program = [
    "bash",
    "-c",
    "MATCH=$$(kubectl get -n istio-system --request-timeout 5s rule stackdriver-tracing-rule -o jsonpath='{.spec.match}'); [ \"$$MATCH\" != 'context.protocol == \"http\" || context.protocol == \"grpc\"' ] && MATCH=\"$$RANDOM\"; jq -n --arg match \"$$MATCH\" '{match:$$match}'",
  ]

  query = {
    depends_on = "${null_resource.istio_tracing_wait.id}"
  }
}

resource "null_resource" "istio_tracing" {
  triggers = {
    match = "${data.external.istio_tracing.result["match"]}"
  }

  provisioner "local-exec" {
    command = "kubectl patch -n istio-system --request-timeout 5s rule stackdriver-tracing-rule -p '{\"spec\":{\"match\":\"context.protocol == \\\"http\\\" || context.protocol == \\\"grpc\\\"\"}}' --type merge"
  }
}
