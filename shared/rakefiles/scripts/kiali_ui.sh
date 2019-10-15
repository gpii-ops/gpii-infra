#!/usr/bin/env sh

# This script starts prot-forwarding to Kiali UI
# and prints a link to access 

set -emou pipefail
LC_CTYPE=C

# Enable debug output if $DEBUG is set to true
[ "${DEBUG:=false}" = 'true' ] && set -x

# Get script name
THIS_SCRIPT="$(basename "${0}")"

# Optional
KIALI_SVC_PORT=${KIALI_SVC_PORT:='20001'}
KIALI_LOCAL_FWD_PORT=${KIALI_LOCAL_FWD_PORT:='20001'}
KIALI_NAMESPACE=${KIALI_NAMESPACE:='istio-system'}
KIALI_SVC_NAME=${KIALI_SVC_NAME:='kiali'}
REQUIRED_BINARIES=${REQUIRED_BINARIES:="kubectl"}

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
kubectl port-forward "service/${KIALI_SVC_NAME}" -n "${KIALI_NAMESPACE}" \
  --address=0.0.0.0 "${KIALI_LOCAL_FWD_PORT}:${KIALI_SVC_PORT}" >/dev/null &
KUBECTL_PID="${!}"

echo "${THIS_SCRIPT}:"
echo "${THIS_SCRIPT}: Kiali port is now being forwarded to your local machine, port ${KIALI_LOCAL_FWD_PORT}."
echo "${THIS_SCRIPT}:"
echo "${THIS_SCRIPT}: You can access Kiali Web UI at:"
echo "${THIS_SCRIPT}: http://localhost:${KIALI_LOCAL_FWD_PORT}/"
echo "${THIS_SCRIPT}:"
echo "${THIS_SCRIPT}: You can close this terminal and port-forwarding by pressing ENTER (new line)."
echo "${THIS_SCRIPT}:"

# idle waiting for abort from user
read -r

# Stop port-forwarding
echo "${THIS_SCRIPT}: Stopping port-forwarding"
kill "${KUBECTL_PID}"

echo "${THIS_SCRIPT}: Done"
