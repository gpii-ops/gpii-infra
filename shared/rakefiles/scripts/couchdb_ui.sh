#!/usr/bin/env sh

# This script starts prot-forwarding to CouchDB service,
# generates temporary credentials and prints link for Web UI access

set -emou pipefail

# Enable debug output if $DEBUG is set to true
[ "${DEBUG:=false}" = 'true' ] && set -x

# Get script name
THIS_SCRIPT="$(basename "${0}")"

# Required env variables
# Try to use TF_* variables
COUCHDB_ADMIN_USERNAME=${COUCHDB_ADMIN_USERNAME:=${TF_VAR_secret_couchdb_admin_username}}
COUCHDB_ADMIN_PASSWORD=${COUCHDB_ADMIN_PASSWORD:=${TF_VAR_secret_couchdb_admin_password}}
COUCHDB_ADMIN_USERNAME=${COUCHDB_ADMIN_USERNAME:?"Environment variable must be set"}
COUCHDB_ADMIN_PASSWORD=${COUCHDB_ADMIN_PASSWORD:?"Environment variable must be set"}

# Optional
COUCHDB_SVC_PORT=${COUCHDB_SVC_PORT:='5984'}
COUCHDB_LOCAL_FWD_PORT=${COUCHDB_LOCAL_FWD_PORT:='35984'}
COUCHDB_NAMESPACE=${COUCHDB_NAMESPACE:='gpii'}
COUCHDB_SVC_NAME=${COUCHDB_SVC_NAME:='couchdb-svc-couchdb'}
REQUIRED_BINARIES=${REQUIRED_BINARIES:="kubectl curl"}

# Check if we have all the dependencies
for BIN in ${REQUIRED_BINARIES}; do
  if [ ! -x "$(command -v "${BIN}")" ]
  then
    echo "${THIS_SCRIPT}: Required dependency ${BIN} not found in path"
    exit 1
  fi
done

# Start port forwarding
kubectl port-forward "service/${COUCHDB_SVC_NAME}" -n "${COUCHDB_NAMESPACE}" --address=0.0.0.0 "${COUCHDB_LOCAL_FWD_PORT}:${COUCHDB_SVC_PORT}" &

echo
echo "CouchDB port is now being forwarded to your local machine, port ${COUCHDB_LOCAL_FWD_PORT}."
echo
echo "You can access CouchDB Web UI at:"
echo "http://${TF_VAR_secret_couchdb_admin_username}:${TF_VAR_secret_couchdb_admin_password}@localhost:35984/_utils"
echo
echo "You can close this terminal and port-forwarding by pressing ctrl+c."

fg

echo "${THIS_SCRIPT}: Done"
