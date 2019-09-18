#!/usr/bin/env sh

# This script quarantines a Node for further analysis after a Security
# Incident.

set -eou pipefail

# Enable debug output if $DEBUG is set to true
[ "${DEBUG:=false}" = 'true' ] && set -x

# Only print commands by default
DRY_RUN=${DRY_RUN:='true'}

# Get script name
THIS_SCRIPT="$(basename "${0}")"

# Required env variables
NODE=${NODE:?"Environment variable must be set"}

# Optional
EGRESS_FIREWALL_RULE_NAME=${EGRESS_FIREWALL_RULE_NAME:='no-access-out'}
INGRESS_FIREWALL_RULE_NAME=${INGRESS_FIREWALL_RULE_NAME:='no-access-in'}

# We assume 'gcloud' and 'kubectl' are configured with appropriate credentials,
# project, cluster, etc. for the environment we will modify.
REQUIRED_BINARIES=${REQUIRED_BINARIES:="gcloud kubectl"}

# Check if we have all the dependencies
for BIN in ${REQUIRED_BINARIES}; do
  if [ ! -x "$(command -v "${BIN}")" ]
  then
    echo "${THIS_SCRIPT}: Required dependency ${BIN} not found in path"
    exit 1
  fi
done

# Utility function to run or pretend to run a command based on the value of
# DRY_RUN.
maybe_run() {
  CMD="${1}"
  if [ "${DRY_RUN}" = 'true' ]; then
    echo "${THIS_SCRIPT}: Pretending to run: ${CMD}"
  else
    echo "${THIS_SCRIPT}: Running: ${CMD}"
    $CMD
  fi
}

# Utility function to calculate zone from NODE.
#
# Cleans up GCP-style path (e.g.
# https://www.googleapis.com/compute/v1/projects/gpii-gcp-dev-tyler/zones/us-central1-a).
get_zone() {
  MY_NODE="${1}"
  gcloud compute instances describe --format json "${MY_NODE}" |
    jq -er '.zone' |
    sed -e 's,.*/,,g'
}

create_firewall_rules() {
  FIREWALL_RULE_CREATE_CMD="gcloud compute firewall-rules create"
  # The network name ('network') is specified by exekube's gke-network module.
  #
  # We use '--priority 1' to leave priority 0 available for e.g. an ssh ingress
  # rule to allow direct inspection of the node.
  FIREWALL_RULE_CREATE_OPTIONS="\
    --action DENY \
    --description Quarantine \
    --network network \
    --priority 1 \
    --rules all \
    --target-tags quarantine \
  "

  # Egress rule
  EGRESS_FIREWALL_RULE_CMD="${FIREWALL_RULE_CREATE_CMD} ${EGRESS_FIREWALL_RULE_NAME} \
    ${FIREWALL_RULE_CREATE_OPTIONS} \
    --direction EGRESS \
    --destination-ranges 0.0.0.0/0 \
  "
  maybe_run "${EGRESS_FIREWALL_RULE_CMD}"

  # Ingress rule
  INGRESS_FIREWALL_RULE_CMD="${FIREWALL_RULE_CREATE_CMD} ${INGRESS_FIREWALL_RULE_NAME} \
    ${FIREWALL_RULE_CREATE_OPTIONS} \
    --direction INGRESS \
    --source-ranges 0.0.0.0/0 \
  "
  maybe_run "${INGRESS_FIREWALL_RULE_CMD}"
}

remove_node_from_instance_group() {
  ZONE=$(get_zone "${NODE}")
  INSTANCE_GROUP=$(
    gcloud compute instances describe --format json "${NODE}" --zone "${ZONE}" |
      jq -er '.metadata.items[] | select(.key == "created-by") | .value' |
      sed -e 's,.*/,,g'
  )
  REMOVE_NODE_FROM_INSTANCE_GROUP_CMD="gcloud compute instance-groups managed abandon-instances ${INSTANCE_GROUP} --instances ${NODE} --zone ${ZONE}"
  maybe_run "${REMOVE_NODE_FROM_INSTANCE_GROUP_CMD}"
}

quarantine_node() {
  QUARANTINE_NODE_CMD="gcloud compute instances add-tags ${NODE} --tags quarantine"
  maybe_run "${QUARANTINE_NODE_CMD}"
}

remove_node_from_cluster() {
  REMOVE_NODE_FROM_CLUSTER_CMD="kubectl delete node ${NODE}"
  maybe_run "${REMOVE_NODE_FROM_CLUSTER_CMD}"
}

destroy_node() {
  ZONE=$(get_zone "${NODE}")
  DESTROY_NODE_CMD="gcloud -q compute instances delete ${NODE} --zone ${ZONE}"
  maybe_run "${DESTROY_NODE_CMD}"
}

delete_firewall_rules() {
  FIREWALL_RULE_DELETE_CMD="gcloud -q compute firewall-rules delete"
  # Egress rule
  EGRESS_FIREWALL_RULE_CMD="${FIREWALL_RULE_DELETE_CMD} ${EGRESS_FIREWALL_RULE_NAME}"
  maybe_run "${EGRESS_FIREWALL_RULE_CMD}"

  # Ingress rule
  INGRESS_FIREWALL_RULE_CMD="${FIREWALL_RULE_DELETE_CMD} ${INGRESS_FIREWALL_RULE_NAME}"
  maybe_run "${INGRESS_FIREWALL_RULE_CMD}"
}

# Main
#
# Comment/uncomment functions below as needed. (This is not an especially
# elegant interface, but the workflow when quarantining nodes due to a Security
# Incident is hard to predict so we decided on a hands-on approach.)
create_firewall_rules
remove_node_from_instance_group
quarantine_node
remove_node_from_cluster
#destroy_node
#delete_firewall_rules


# vim: et ts=2 sw=2:
