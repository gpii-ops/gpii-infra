variable "environment" {}

output "couchdb_volume_id" {
  value = "${aws_ebs_volume.couchdb.id}"
}
