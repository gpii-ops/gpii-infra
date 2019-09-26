resource "google_logging_metric" "compute_firewalls_modify" {
  name   = "compute.firewalls.modify"
  filter = "resource.type=\"gce_firewall_rule\" AND (protoPayload.methodName:\"compute.firewalls.insert\" OR protoPayload.methodName:\"compute.firewalls.patch\" OR protoPayload.methodName:\"compute.firewalls.update\" OR protoPayload.methodName:\"compute.firewalls.delete\")"

  metric_descriptor {
    metric_kind = "DELTA"
    value_type  = "INT64"
  }
}
