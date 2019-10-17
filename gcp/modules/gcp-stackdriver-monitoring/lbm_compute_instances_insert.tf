resource "google_logging_metric" "compute_instances_insert" {
  depends_on = ["null_resource.destroy_old_stackdriver_resources"]
  name       = "compute.instances.insert"
  filter     = "resource.type=\"gce_instance\" AND (protoPayload.methodName=\"beta.compute.instances.insert\" OR protoPayload.methodName=\"compute.instances.insert\") AND protoPayload.authenticationInfo.principalEmail!=\"${var.organization_id}@cloudservices.gserviceaccount.com\""

  metric_descriptor {
    metric_kind = "DELTA"
    value_type  = "INT64"
  }
}
