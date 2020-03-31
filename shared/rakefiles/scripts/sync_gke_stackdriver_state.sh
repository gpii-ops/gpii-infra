#!/usr/bin/env sh

# This script goes through a list of StackDriver ConfigMaps ($STACKDRIVER_CONFIGMAPS) and tries to
# import them into Terraform state in given Terragrunt module
# ($STACKDRIVER_MODULE_DIR). This is intended to sync Terraform state with actual
# state, as Stackdriver components on GKE are managed by Google.

set -eou pipefail

# enable debug output if $DEBUG is set to true
[ "${DEBUG:=false}" = 'true' ] && set -x

# get script name
THIS_SCRIPT="$(basename "${0}")"

# list of env variables - interface
# required
ENV=${ENV:?"Environment variable must be set"}
# optional
STACKDRIVER_MODULE_DIR=${STACKDRIVER_MODULE_DIR:="live/${ENV}/k8s/stackdriver-gke"}
STACKDRIVER_CONFIGMAPS=${STACKDRIVER_CONFIGMAPS:="metadata-agent-config"}
REQUIRED_BINARIES=${REQUIRED_BINARIES:="kubectl terragrunt jq"}

# check the module does exist, otherwise silently exit
if [ ! -d "${STACKDRIVER_MODULE_DIR}" ]
then
  echo "${THIS_SCRIPT}: Skipping Stackdriver ConfigMap state synchronization, module not found (${STACKDRIVER_MODULE_DIR})"
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
if ! RESOURCES="$(terragrunt state pull --terragrunt-working-dir "${STACKDRIVER_MODULE_DIR}" | sed 's/^o://g' | jq -ers '.[].modules[].resources')"
then
  echo "${THIS_SCRIPT}: Failed to retrieve or parse Terraform state"
  exit 1
fi

# iterate through the list of HPAs
for CM in ${STACKDRIVER_CONFIGMAPS}; do
  # if configmap is not in state already
  if ! echo "${RESOURCES}" | jq -ers ".[].\"kubernetes_config_map.${CM}\"" >/dev/null
  then
    # and if CM exists
    if kubectl get configmap "${CM}" -n kube-system --request-timeout='5s' >/dev/null
    then
      echo "${THIS_SCRIPT}: Trying to import GKE Stackdriver ConfigMap - ${CM}"
      # import it to TF state
      terragrunt import "kubernetes_config_map.${CM}" "kube-system/${CM}" --terragrunt-working-dir "${STACKDRIVER_MODULE_DIR}"
    fi
  fi
done

echo "${THIS_SCRIPT}: Done"
