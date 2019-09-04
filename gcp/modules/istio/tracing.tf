data "external" "istio_tracing" {
  program = [
    "bash",
    "-c",
    "MATCH=$$(kubectl get -n istio-system --request-timeout 5s rule stackdriver-tracing-rule -o jsonpath='{.spec.match}'); [ \"$$MATCH\" != 'context.protocol == \"http\" || context.protocol == \"grpc\"' ] && MATCH=\"$$RANDOM\"; jq -n --arg match \"$$MATCH\" '{match:$$match}'",
  ]
}

resource "null_resource" "istio_tracing" {
  triggers = {
    match = "${data.external.istio_tracing.result.match}"
  }

  provisioner "local-exec" {
    command = "kubectl patch -n istio-system --request-timeout 5s rule stackdriver-tracing-rule -p '{\"spec\":{\"match\":\"context.protocol == \\\"http\\\" || context.protocol == \\\"grpc\\\"\"}}' --type merge"
  }
}
