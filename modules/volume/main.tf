resource "aws_ebs_volume" "couchdb_us-east-2a" {
  availability_zone = "us-east-2a"
  size = 5
  encrypted = true
  tags {
    Name = "${var.environment} couchdb us-east-2a pv"
    Environment = "${var.environment}"
    Terraform = true
  }
}

resource "aws_ebs_volume" "couchdb_us-east-2b" {
  availability_zone = "us-east-2b"
  size = 5
  encrypted = true
  tags {
    Name = "${var.environment} couchdb us-east-2b pv"
    Environment = "${var.environment}"
    Terraform = true
  }
}

resource "aws_ebs_volume" "couchdb_us-east-2c" {
  availability_zone = "us-east-2c"
  size = 5
  encrypted = true
  tags {
    Name = "${var.environment} couchdb us-east-2c pv"
    Environment = "${var.environment}"
    Terraform = true
  }
}
