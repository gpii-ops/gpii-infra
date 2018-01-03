variable "cluster_name" {}

output "cluster_log_name" {
  value = "${aws_cloudwatch_log_group.main.name}"
}
