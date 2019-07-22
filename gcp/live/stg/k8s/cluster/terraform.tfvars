# ↓ Module metadata

terragrunt = {
  terraform {
    source = "/project/modules//gke-cluster"
  }

  dependencies {
    paths = [
      "../stackdriver/exclusion",
      "../stackdriver/export",
    ]
  }

  include = {
    path = "${find_in_parent_folders()}"
  }
}

# ↓ Module configuration (empty means all default)

node_type = "n1-highcpu-8"

# This is to prevent accidental deletion of a long-lived cluster (e.g. due to
# changing a parameter like 'oauth_scopes').
#
# If you are sure you want to destroy a cluster, do not change this variable![1]
# Instead, see instructions in the 'cluster_protector' resource in
# gcp/modules/gke-cluster/main.tf.
#
# [1] You can change this variable if you want, but it won't take effect until
# you change 'cluster_protector'. I recommend leaving this variable alone when
# temporarily allowing a cluster to be destroyed.
prevent_destroy_cluster = true

binary_authorization_evaluation_mode = "ALWAYS_DENY"
