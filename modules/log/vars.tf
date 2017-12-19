variable "environment" {}

output "cluster_log_name" {
  value = "${aws_cloudwatch_log_group.main.name}"
}
