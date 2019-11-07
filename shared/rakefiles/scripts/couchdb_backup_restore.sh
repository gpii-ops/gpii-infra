#!/usr/bin/env sh

# This script restores CouchDB disks from set of snapshots.
# By default latest set of available snapshots will be used,
# alternatively snapshots names can be passed via 
# COUCHDB_SOURCE_SNAPSHOTS variable

set -emou pipefail
LC_CTYPE=C

# Enable debug output if $DEBUG is set to true
[ "${DEBUG:=false}" = 'true' ] && set -x
# DEBUG set messes up kubectl output
unset DEBUG

# Get script name
THIS_SCRIPT="$(basename "${0}")"

# Optional
COUCHDB_SOURCE_SNAPSHOTS=${COUCHDB_SOURCE_SNAPSHOTS:=''}
COUCHDB_NAMESPACE=${COUCHDB_NAMESPACE:='gpii'}
COUCHDB_STATEFULSET_NAME=${COUCHDB_STATEFULSET_NAME:='couchdb-couchdb'}
COUCHDB_SNAPSHOT_PREFIX=${COUCHDB_SNAPSHOT_PREFIX:='pv-database-storage-couchdb-couchdb'}
COUCHDB_PVC_FILTER=${COUCHDB_PVC_FILTER:='app=couchdb'}
COUCHDB_POD_FILTER=${COUCHDB_POD_FILTER:='app=couchdb'}
DEPLOYMENTS_NAMES=${DEPLOYMENTS_NAMES:='preferences flowmanager'}
DEPLOYMENTS_NAMESPACE=${DEPLOYMENTS_NAMESPACE:='gpii'}
K8S_SNAPSHOTS_NAMESPACE=${K8S_SNAPSHOTS_NAMESPACE:='kube-system'}
K8S_SNAPSHOTS_DEPLOYMENT_NAME=${K8S_SNAPSHOTS_DEPLOYMENT_NAME:='k8s-snapshots'}
REQUIRED_BINARIES=${REQUIRED_BINARIES:='kubectl gcloud jq awk'}
MAX_RETRIES=${MAX_RETRIES:='30'}
SLEEP=${SLEEP:='10'}
PRINT_PREFIX=${PRINT_PREFIX="${THIS_SCRIPT}: "}
PAUSE_BEFORE_SCALING_UP=${PAUSE_BEFORE_SCALING_UP:='true'}
ENV=${ENV:='unknown'}

# If we're in a known env, we can skip the pause
if [ "${ENV}" = 'dev' ] || [ "${ENV}" = 'stg' ]; then
  PAUSE_BEFORE_SCALING_UP='false'
fi

# Check if we have colors available, it looks good
check_colors(){
  if command -v tput > /dev/null; then
    COLORS="$(tput colors)"
    if [ -n "${COLORS}" ] && [ "${COLORS}" -ge 8 ]; then
      GREEN="$(tput setaf 2)"
      RED="$(tput setaf 1)"
      YELLOW="$(tput setaf 3)"
      NOCOL="$(tput sgr0)"
    fi
  else
    GREEN=''
    RED=''
    YELLOW=''
    NOCOL=''
  fi
}

# Print message
print() {
  echo "${YELLOW}${PRINT_PREFIX}${NOCOL}$*"
}

# Print error and exit
fail() {
  print "${RED}ERROR: $*${NOCOL}"
  exit 1
}

# Print section header
print_header() {
  print
  print "## ${GREEN}$*${NOCOL}"
}

# Check if we have all the dependencies
verify_binaries() {
  for bin in ${REQUIRED_BINARIES}; do
    [ -x "$(command -v "${bin}")" ] || fail "Required dependency ${bin} not found in path"
  done
}

# Scale resource of kind $1 and name $2 in namespace $3 to given number of replicas $4
scale_and_wait() {
  kind=${1:?'Resource Kind must be set'}
  name=${2:?'Resource Name must be set'}
  namespace=${3:?'Resource Namespace must be set'}
  replicas=${4:?'Number of replicas must be set'}

  print "Scaling ${kind} ${namespace}/${name} to ${replicas} replicas"
  kubectl -n "${namespace}" scale "${kind}/${name}" --replicas="${replicas}"

  # Wait for given number of repicas
  retries=0
  ready='false'
  if [ "${replicas}" -gt 0 ]; then
    while [ "${retries}" -lt "${MAX_RETRIES}" ] && [ "${ready}" != 'true' ]; do
      [ "$(kubectl -n "${namespace}" get "${kind}" "${name}" -o jsonpath='{.status.readyReplicas}')" = "${replicas}" ] && ready='true'
      [ "${ready}" != 'true' ] && printf '.' && sleep "${SLEEP}"
      retries=$((retries + 1))
    done
    # shellcheck disable=SC2015
    [ "${ready}" = 'true' ] && printf '\n' || fail "Time-out while waiting for ${kind}/${name}" 
  fi
}

# Reads names of Couchdb snapshots
read_latest_couchdb_snapshots() {
  snapshots=''
  for i in $(seq 0 "$((COUCHDB_REPLICAS-1))"); do
    snapshots="${snapshots} $(gcloud compute snapshots list --sort-by='~creationTimestamp' --limit=1 --format='json' \
                   --filter="name~'${COUCHDB_SNAPSHOT_PREFIX}-${i}-*'" \
                   | jq -re '.[0].name')"
  done
  COUCHDB_SOURCE_SNAPSHOTS="$(echo "${snapshots}" | awk '{$1=$1};1')"
}

# Check that snapshots are available
check_snapshots() {
  for s in ${COUCHDB_SOURCE_SNAPSHOTS}; do
    gcloud compute snapshots describe "${s}" > /dev/null
  done
}

# Restores volumes from snapshots
restore_disks() {
  i=1

  for volume in ${COUCHDB_PVS}; do
    print "Restoring volume ${volume}"
    pv_info="$(kubectl get pv "${volume}" -o json)"
    disk_name="$(printf '%s' "${pv_info}" | jq -er '.spec.gcePersistentDisk.pdName')"
    disk_zone="$(printf '%s' "${pv_info}" | jq -er '.metadata.labels."failure-domain.beta.kubernetes.io/zone"')"
    disk_info="$(gcloud compute disks describe "${disk_name}" --zone "${disk_zone}" --format json)"
    disk_size="$(printf '%s' "${disk_info}" | jq -er '.sizeGb')"
    disk_desc="$(printf '%s' "${disk_info}" | jq -er '.description')"
    disk_type="$(printf '%s' "${disk_info}" | jq -er '.type | split("/")[-1]')"

    snapshot="$(echo "${COUCHDB_SOURCE_SNAPSHOTS}" | cut -f"${i}" -d' ')"
    i=$((i + 1))

    print "- Deleting disk ${disk_name}"
    gcloud compute disks delete "${disk_name}" --zone "${disk_zone}" --quiet
   
    print "- Creating disk ${disk_name} (${disk_zone}, ${disk_size} GB, ${disk_type})"
    print "  from snapshot ${snapshot}"
    gcloud compute disks create "${disk_name}" --zone "${disk_zone}" \
                                  --description="${disk_desc}" \
                                  --size "${disk_size}GB" \
                                  --type "${disk_type}" \
                                  --source-snapshot "${snapshot}"

  done 
}

# Check CouchDB Cluster health
check_couchdb_health() {
  # Wait until each node has OK status
  for i in $(seq 0 "$((COUCHDB_REPLICAS-1))"); do
    print "Waiting for ${COUCHDB_STATEFULSET_NAME}-${i}"
    retries=0
    status='false'
    
    while [ "${retries}" -lt "${MAX_RETRIES}" ] && [ "${status}" != 'ok' ]; do

      # shellcheck disable=SC2016
      status="$(kubectl exec -n "${COUCHDB_NAMESPACE}" -it "${COUCHDB_STATEFULSET_NAME}-${i}" -c couchdb -- \
        sh -c 'curl -s http://$COUCHDB_USER:$COUCHDB_PASSWORD@127.0.0.1:5984/_up' | jq -re '.status')"
      [ "${status}" != 'ok' ] && printf '.' && sleep "${SLEEP}"
      
      retries=$((retries + 1))
    done
    # shellcheck disable=SC2015
    [ "${status}" = 'ok' ] && printf '\n' || fail "Time-out while waiting for ${COUCHDB_STATEFULSET_NAME}-${i}" 
  done

  # Wait until all the nodes are listed as cluster_nodes 
  print "Checking membership status"
  retries=0
  nodes=0
  while [ "${retries}" -lt "${MAX_RETRIES}" ] && [ "${nodes}" != "${COUCHDB_REPLICAS}" ]; do

    # shellcheck disable=SC2016
    nodes="$(kubectl exec -n "${COUCHDB_NAMESPACE}" -it "${COUCHDB_STATEFULSET_NAME}-0" -c couchdb -- \
      sh -c 'curl -s http://$COUCHDB_USER:$COUCHDB_PASSWORD@127.0.0.1:5984/_membership' | jq -re '.cluster_nodes | length')"
    [ "${nodes}" != "${COUCHDB_REPLICAS}" ] && printf '.' && sleep "${SLEEP}"

    retries=$((retries + 1))
  done
  # shellcheck disable=SC2015
  [ "${nodes}" = "${COUCHDB_REPLICAS}" ] && printf '\n' || fail "Time-out while waiting for CouchDB membership" 
}


# Init helper functions
check_colors

# Check prerequisites
print_header "Checking prerequisites"
verify_binaries

# Read num of Couch replicas
print_header "Reading current set of replicas"
COUCHDB_REPLICAS="$(kubectl -n "${COUCHDB_NAMESPACE}" get statefulset "${COUCHDB_STATEFULSET_NAME}" -o jsonpath='{.status.replicas}')"

# If not supplied read set of latest snapshots
if [ "${COUCHDB_SOURCE_SNAPSHOTS}" = '' ]; then
  print_header "Reading latest set of snapshots"
  read_latest_couchdb_snapshots
fi

# Check that number of snaphsots matches number of replicas
[ "$(echo "${COUCHDB_SOURCE_SNAPSHOTS}" | wc -w | awk '{$1=$1};1')" = "${COUCHDB_REPLICAS}" ] \
  || fail "Number of CouchDB snapshots (${COUCHDB_SOURCE_SNAPSHOTS}) does not match number of replicas (${COUCHDB_REPLICAS})"
print "Snapshots to restore from: ${COUCHDB_SOURCE_SNAPSHOTS}"

# Check snapshots
print_header "Checking snapshots availability"
check_snapshots

# Scale services to 0
print_header "Scaling down services"
for d in $DEPLOYMENTS_NAMES; do
  scale_and_wait deployment "${d}" "${DEPLOYMENTS_NAMESPACE}" 0
done

# Read names of current Couch volumes
print_header "Reading CouchDB volume names"
COUCHDB_PVS="$(kubectl -n "${COUCHDB_NAMESPACE}" get pvc -l "${COUCHDB_PVC_FILTER}" \
                 --sort-by '.metadata.name' -o json | jq -re '.items[].spec.volumeName')"

# Scale CouchDB to 0
print_header "Scaling down CouchDB"
scale_and_wait statefulset "${COUCHDB_STATEFULSET_NAME}" "${COUCHDB_NAMESPACE}" 0

# Wait for pods to disappear
print "Waiting for all pods to terminate"
kubectl wait pods -l="${COUCHDB_POD_FILTER}" -n "${COUCHDB_NAMESPACE}" --for=delete --timeout="$((MAX_RETRIES * SLEEP))s"

# Scale K8s snapshots to 0
print_header "Scaling down k8s-snapshots"
scale_and_wait deployment "${K8S_SNAPSHOTS_DEPLOYMENT_NAME}" "${K8S_SNAPSHOTS_NAMESPACE}" 0

# Restore individual CouchDB disks
print_header "Restoring disks"
restore_disks

# Scale CouchDB back
print_header "Scaling up CouchDB"
scale_and_wait statefulset "${COUCHDB_STATEFULSET_NAME}" "${COUCHDB_NAMESPACE}" "${COUCHDB_REPLICAS}"

# Check CouchDB Health
print_header "Checking CouchDB health"
check_couchdb_health

# Give a user chance to make additional checks
if [ "${PAUSE_BEFORE_SCALING_UP}" != 'false' ]; then
  print ''
  print 'If you want to make additional checks of CouchDB before scaling the services up,'
  print 'now is the time (press ENTER to continue).'
  read -r
fi

# Scale services back
print_header "Scaling up services"
for d in $DEPLOYMENTS_NAMES; do
  scale_and_wait deployment "${d}" "${DEPLOYMENTS_NAMESPACE}" 3
done

# Scale K8s snapshots back
print_header "Scaling up k8s-snapshots"
scale_and_wait deployment "${K8S_SNAPSHOTS_DEPLOYMENT_NAME}" "${K8S_SNAPSHOTS_NAMESPACE}" 1

print_header "Done"
