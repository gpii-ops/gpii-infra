resource "google_logging_metric" "disks_createsnapshot" {
  name   = "compute.disks.createSnapshot"
  filter = "resource.type=\"gce_disk\" AND protoPayload.methodName=\"v1.compute.disks.createSnapshot\""
}
