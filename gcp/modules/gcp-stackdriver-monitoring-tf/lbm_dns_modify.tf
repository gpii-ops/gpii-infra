resource "google_logging_metric" "dns_modify" {
  name   = "dns.modify"
  filter = "resource.type=\"dns_managed_zone\" AND (protoPayload.methodName=\"dns.changes.create\" OR protoPayload.methodName=\"dns.managedZones.delete\" OR protoPayload.methodName=\"dns.managedZones.patch\" OR protoPayload.methodName=\"dns.managedZones.update\")"

  metric_descriptor {
    metric_kind = "DELTA"
    value_type  = "INT64"
  }
}
