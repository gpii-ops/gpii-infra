# I wish I didn't have to re-declare a provider here, but I couldn't figure out
# how to avoid it.
#
# I *really* wish I could use ${data.terraform_remote_state.base.region} but
# it's empty when I try to call it. Maybe because I need a provider to run the
# data stanza that would fill in these values?
provider "aws" {
  version = "~> 1.8"
  region = "us-east-2"
}
