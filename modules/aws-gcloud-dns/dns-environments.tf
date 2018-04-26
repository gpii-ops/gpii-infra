# This code will create two zones at AWS Route53
#
# * aws.gpii.net
# * gcp.gpii.net
#
# The zones will be delegated to Google DNS. Also the zones are created at
# Google DNS.

module "aws_zone" {
  source = "./dnszone"
  recordname = "aws"
}

module "gcp_zone" {
  source = "./dnszone"
  recordname = "gcp"
}


