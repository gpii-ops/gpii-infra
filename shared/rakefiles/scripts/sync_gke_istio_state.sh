#!/usr/bin/env sh

# This script goes through a list of Istio HPAs ($ISTIO_HPAS) and tries to
# import them into Terraform state in given Terragrunt module
# ($ISTIO_MODULE_DIR). This is intended to sync Terraform state with actual
# state, as istio components on GKE are managed by Google.

set -eou pipefail

# enable debug output if $DEBUG is set to true
[ "${DEBUG:=false}" = 'true' ] && set -x

# get script name
THIS_SCRIPT="$(basename "${0}")"

# list of env variables - interface
# required
ENV=${ENV:?"Environment variable must be set"}
# optional
ISTIO_MODULE_DIR=${ISTIO_MODULE_DIR:="live/${ENV}/k8s/istio"}
ISTIO_HPAS=${ISTIO_HPAS:="istio-egressgateway istio-ingressgateway istio-pilot istio-policy istio-telemetry"}
REQUIRED_BINARIES=${REQUIRED_BINARIES:="kubectl terragrunt jq"}

# check the module does exist, otherwise silently exit
if [ ! -d "${ISTIO_MODULE_DIR}" ]
then
  echo "${THIS_SCRIPT}: Skipping Istio HPA state synchronization, Istio module not found (${ISTIO_MODULE_DIR})"
  exit 0
fi

# check if we have all the dependencies
for BIN in ${REQUIRED_BINARIES}; do
  if [ ! -x "$(command -v "${BIN}")" ]
  then
    echo "${THIS_SCRIPT}: Required dependency ${BIN} not found in path"
    exit 1
  fi
done

# retrieve TF state, remove "o:" which is weird artifact added to output when
# running terraform in terraform
if ! RESOURCES="$(terragrunt state pull --terragrunt-working-dir "${ISTIO_MODULE_DIR}" | sed 's/^o://g' | jq -ers '.[].modules[].resources')"
then
  echo "${THIS_SCRIPT}: Failed to retrieve or parse Terraform state"
  exit 1
fi

# iterate through the list of HPAs
for HPA in ${ISTIO_HPAS}; do
  # if hpa is not in state already
  if ! echo "${RESOURCES}" | jq -ers ".[].\"kubernetes_horizontal_pod_autoscaler.${HPA}\"" >/dev/null
  then
    # and if hpa exists
    if kubectl get hpa "${HPA}" -n istio-system --request-timeout='5s' >/dev/null
    then
      echo "${THIS_SCRIPT}: Trying to import GKE Istio HPA - ${HPA}"
      # import it to TF state
      terragrunt import "kubernetes_horizontal_pod_autoscaler.${HPA}" "istio-system/${HPA}" --terragrunt-working-dir "${ISTIO_MODULE_DIR}"
    fi
  fi
done

echo "${THIS_SCRIPT}: Done"
