provider "aws" {
  version = "~> 1.8"
  region = "us-east-2"
}
provider "google" {
  credentials = "${file("key.json")}"
  project     = "${var.gke_project}"
  region      = "us-east4"
}
