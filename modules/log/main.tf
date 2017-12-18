resource "aws_cloudwatch_log_group" "main" {
  name = "${var.environment}.gpii.net"

# The logs shouldn't be removed between deployments, but we have to set the
# scope in terraform to avoid issues at the 'detroy' step.
#  lifecycle {
#    prevent_destroy = true
#  }

  tags {
    Environment = "${var.environment}"
    Terraform = true
  }
}
