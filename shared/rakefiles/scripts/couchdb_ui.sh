#!/usr/bin/env sh

# This script starts prot-forwarding to CouchDB service,
# generates temporary credentials and prints link for Web UI access

set -emou pipefail
LC_CTYPE=C

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
ENV=${ENV:?"Environment variable must be set"}

# Optional
COUCHDB_SVC_PORT=${COUCHDB_SVC_PORT:='5984'}
COUCHDB_LOCAL_FWD_PORT=${COUCHDB_LOCAL_FWD_PORT:='35984'}
COUCHDB_NAMESPACE=${COUCHDB_NAMESPACE:='gpii'}
COUCHDB_SVC_NAME=${COUCHDB_SVC_NAME:='couchdb-svc-couchdb'}
COUCHDB_UI_USERNAME=${COUCHDB_UI_USERNAME:='ui'}
COUCHDB_UI_PASSWORD_DIR=${COUCHDB_UI_PASSWORD_PATH_PREFIX:="/project/live/${ENV}/secrets/couchdb"}
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
echo "${THIS_SCRIPT}: Starting port-forwarding"
kubectl port-forward "service/${COUCHDB_SVC_NAME}" -n "${COUCHDB_NAMESPACE}" \
  --address=0.0.0.0 "${COUCHDB_LOCAL_FWD_PORT}:${COUCHDB_SVC_PORT}" >/dev/null &
KUBECTL_PID="${!}"

# Set target CouchDB url
HOST="http://${COUCHDB_ADMIN_USERNAME}:${COUCHDB_ADMIN_PASSWORD}@localhost:${COUCHDB_LOCAL_FWD_PORT}"

# Wait for CouchDB
while ! curl -s -o /dev/null -m10 "${HOST}/_up"; do
  echo "${THIS_SCRIPT}: Waiting for CouchDB port to be available..."
  sleep 1
done

# Get unique hash for cluster
CLUSTER_HASH="$(kubectl config view --output json | jq -ers '.[].clusters[].cluster.server | @base64')"
COUCHDB_UI_PASSWORD_FILE="${COUCHDB_UI_PASSWORD_DIR}/ui-${CLUSTER_HASH}.password"

# Create a password for a current cluster if it doesn't exist
if [ ! -f "${COUCHDB_UI_PASSWORD_FILE}" ]; then
  mkdir -p "${COUCHDB_UI_PASSWORD_DIR}"
  # Clean up any existing old passwords
  rm -f "${COUCHDB_UI_PASSWORD_DIR}"/*
  tr -dc 'A-Za-z0-9' < /dev/urandom | fold -w 32 | head -n 1 > "${COUCHDB_UI_PASSWORD_FILE}" || true
fi

COUCHDB_UI_PASSWORD="$(cat "${COUCHDB_UI_PASSWORD_FILE}")"

# Create a new user
echo "${THIS_SCRIPT}: Creating temporary UI user (${COUCHDB_UI_USERNAME})"

curl -s -o /dev/null -X PUT "${HOST}/_node/_local/_config/admins/${COUCHDB_UI_USERNAME}" \
  -d "\"${COUCHDB_UI_PASSWORD}\""

echo "${THIS_SCRIPT}:"
echo "${THIS_SCRIPT}: CouchDB port is now being forwarded to your local machine, port ${COUCHDB_LOCAL_FWD_PORT}."
echo "${THIS_SCRIPT}:"
echo "${THIS_SCRIPT}: You can access CouchDB Web UI at:"
echo "${THIS_SCRIPT}: http://${COUCHDB_UI_USERNAME}:${COUCHDB_UI_PASSWORD}@localhost:${COUCHDB_LOCAL_FWD_PORT}/_utils"
echo "${THIS_SCRIPT}:"
echo "${THIS_SCRIPT}: Some browsers require credentials to be entered manually:"
echo "${THIS_SCRIPT}:   username: ${COUCHDB_UI_USERNAME}"
echo "${THIS_SCRIPT}:   password: ${COUCHDB_UI_PASSWORD}"
echo "${THIS_SCRIPT}:"
echo "${THIS_SCRIPT}: You can close this terminal and port-forwarding by pressing ENTER (new line)."
echo "${THIS_SCRIPT}:"

# idle waiting for abort from user
read -r

# Clean up temporary ui user
echo "${THIS_SCRIPT}: Removing temporary UI user (${COUCHDB_UI_USERNAME})"
curl -s -o /dev/null -X DELETE "${HOST}/_node/_local/_config/admins/${COUCHDB_UI_USERNAME}"

# Stop port-forwarding
echo "${THIS_SCRIPT}: Stopping port-forwarding"
kill "${KUBECTL_PID}"

echo "${THIS_SCRIPT}: Done"
