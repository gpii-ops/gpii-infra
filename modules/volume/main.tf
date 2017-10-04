resource "aws_ebs_volume" "couchdb" {
  availability_zone = "us-east-2a"
  size = 5
  encrypted = true
  tags {
    Name = "couchdb pv ${var.environment}"
    Environment = "${var.environment}"
    Terraform = true
  }
}
