terraform {
  backend "gcs" {}
}

variable "values_dir" {}

variable "env" {}

variable "dns_zones" {
  type = "map"
}

# COUCHDB

variable "couchdb_admin_username" {}
variable "couchdb_admin_password" {}
variable "couchdb_secret" {}

data "template_file" "couchdb_values" {
  template = "${file("values/couchdb.yaml")}"

  vars {
    env                    = "${var.env}"
    couchdb_admin_username = "${var.couchdb_admin_username}"
    couchdb_admin_password = "${var.couchdb_admin_password}"
    couchdb_secret         = "${var.couchdb_secret}"
  }
}

resource "local_file" "couchdb_values_rendered" {
  content  = "${data.template_file.couchdb_values.rendered}"
  filename = "${var.values_dir}/couchdb.yaml"
}

# END COUCHDB

# GPII PREFERENCES

variable "preferences_repository" {}
variable "preferences_checksum" {}

data "template_file" "preferences_values" {
  template = "${file("values/gpii-preferences.yaml")}"

  vars {
    env                    = "${var.env}"
    dns_name               = "${var.dns_zones["${var.env}-gcp-gpii-net"]}"
    preferences_repository = "${var.preferences_repository}"
    preferences_checksum   = "${var.preferences_checksum}"
    couchdb_admin_username = "${var.couchdb_admin_username}"
    couchdb_admin_password = "${var.couchdb_admin_password}"
  }
}

resource "local_file" "preferences_values_rendered" {
  content  = "${data.template_file.preferences_values.rendered}"
  filename = "${var.values_dir}/gpii-preferences.yaml"
}

# END GPII PREFERENCES

# GPII FLOWMANAGER

variable "flowmanager_repository" {}
variable "flowmanager_checksum" {}

data "template_file" "flowmanager_values" {
  template = "${file("values/gpii-flowmanager.yaml")}"

  vars {
    env                    = "${var.env}"
    dns_name               = "${var.dns_zones["${var.env}-gcp-gpii-net"]}"
    flowmanager_repository = "${var.flowmanager_repository}"
    flowmanager_checksum   = "${var.flowmanager_checksum}"
    couchdb_admin_username = "${var.couchdb_admin_username}"
    couchdb_admin_password = "${var.couchdb_admin_password}"
  }
}

resource "local_file" "flowmanager_values_rendered" {
  content  = "${data.template_file.flowmanager_values.rendered}"
  filename = "${var.values_dir}/gpii-flowmanager.yaml"
}

# END GPII FLOWMANAGER

# GPII DATALOADER

variable "dataloader_repository" {}
variable "dataloader_checksum" {}

data "template_file" "dataloader_values" {
  template = "${file("values/gpii-dataloader.yaml")}"

  vars {
    dataloader_repository  = "${var.dataloader_repository}"
    dataloader_checksum    = "${var.dataloader_checksum}"
    couchdb_admin_username = "${var.couchdb_admin_username}"
    couchdb_admin_password = "${var.couchdb_admin_password}"
  }
}

resource "local_file" "dataloader_values_rendered" {
  content  = "${data.template_file.dataloader_values.rendered}"
  filename = "${var.values_dir}/gpii-dataloader.yaml"
}

# END GPII DATALOADER

