variable "environment" {}

output "cluster_log_id" {
  value = "${aws_cloudwatch_log_group.main.name}"
}
