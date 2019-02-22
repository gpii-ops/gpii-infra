terraform {
  backend "gcs" {}
}

variable "name" {
  default = "snapshot-vm"
}

variable "project_id" {
  default = ""
}

variable "region" {
  default = "us-central1-b"
}

variable "snapshots" {
  # temporal values for testing
  default = [
    "pv-database-storage-couchdb-couchdb-1-060219-195159",
    "pv-database-storage-couchdb-couchdb-0-060219-195128",
  ]

  type = "list"
}

resource "random_id" "instance_id" {
  byte_length = 8
}

resource "google_compute_instance" "default" {
  name         = "${var.name}-${random_id.instance_id.hex}"
  machine_type = "n1-standard-8"
  zone         = "${var.region}"
  project      = "${var.project_id}"

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-9"
      size  = 20
      type  = "pd-ssd"
    }
  }

  metadata_startup_script = "${file("${path.module}/backup-snapshots.sh")}"

  # Local SSD disk
  scratch_disk {
    interface = "NVME"
  }

  # Allow Terraform stop the instance for applying the updates
  allow_stopping_for_update = true

  network_interface {
    network = "${google_compute_network.snapshot_vm_network.self_link}"

    access_config {
      // Include this section to give the VM an external ip address
    }
  }

  service_account {
    scopes = [
      "https://www.googleapis.com/auth/cloud.useraccounts.readonly",
      "https://www.googleapis.com/auth/cloudruntimeconfig",
      "https://www.googleapis.com/auth/compute",
      "https://www.googleapis.com/auth/devstorage.read_write",
      "https://www.googleapis.com/auth/logging.write",
      "https://www.googleapis.com/auth/monitoring.write",
    ]
  }

  // Apply the firewall rule to allow external IPs to access this instance
  tags = ["${var.name}", "ssh", "snapshot-mgmt"]
}

# Get a list of last snapshots to set the 'snapshots' variable
#data "external" "snapshots" {
#  program = ["sh","${path.module}/get_snapshots.sh"]
#}

resource "google_compute_attached_disk" "snapshot_attach_disk" {
  count    = "${length(var.snapshots)}"
  disk     = "${google_compute_disk.snapshot_disk.*.self_link[count.index]}"
  instance = "${google_compute_instance.default.self_link}"

  # READ_ONLY doesn't allow to mount due the disk needs a recovery process
  #mode     = "READ_ONLY"

  device_name = "${var.snapshots[count.index]}"
}

resource "google_compute_disk" "snapshot_disk" {
  count    = "${length(var.snapshots)}"
  name     = "${var.snapshots[count.index]}"
  project  = "${var.project_id}"
  zone     = "${var.region}"
  snapshot = "${var.snapshots[count.index]}"
}

resource "google_compute_network" "snapshot_vm_network" {
  name                    = "snapshot-vm-network"
  auto_create_subnetworks = "true"
  project                 = "${var.project_id}"
}

resource "google_compute_firewall" "snapshot_vm_network" {
  name    = "ssh-firewall"
  network = "${google_compute_network.snapshot_vm_network.self_link}"
  project = "${var.project_id}"

  allow {
    protocol = "icmp"
  }

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["ssh"]
}

output "ip" {
  value = "${google_compute_instance.default.network_interface.0.access_config.0.nat_ip}"
}

output "name" {
  value = "${google_compute_instance.default.name}"
}
