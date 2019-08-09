#!/usr/bin/env sh

# This script cleans orphaned FW rules across all projects

# Enable debug output if $DEBUG is set to true
[ "${DEBUG:=false}" = 'true' ] && set -x

# Only print commands to delete rules by default
DRY_RUN=${DRY_RUN:='true'}

# Get projects
PROJECTS=$(gcloud projects list --format="value(project_id)")

for p in ${PROJECTS}; do
  echo "## ${p}:"
  # Get GKE cluster tag
  GCP_TAG="$(gcloud -q --project "${p}" compute instance-templates list --filter="name : gke-k8s-cluster-terraform" --format="value(properties.tags.items[0])" --limit=1 2>/dev/null)"

  # Verify we have expected number of rules with tag (5 or 0)
  echo "GKE FWs:     $(gcloud -q --project "${p}" compute firewall-rules list --filter="targetTags :( ${GCP_TAG} )" --format="value(name)" 2>/dev/null | wc -l)"

  # Count bad - orphaned - rules
  BAD_FW_RULES="$(gcloud -q --project "${p}" compute firewall-rules list --filter="NOT targetTags :( ${GCP_TAG} )" --format="value(name)" 2>/dev/null | tr '\r\n' ' ')"
  echo "Bad FWs:     $(echo "${BAD_FW_RULES}" | wc -w)"
  
  # If we have any bad rules, delete them 
  if [ -n "${BAD_FW_RULES}" ]; then
    if [ "${DRY_RUN}" = 'true' ] || [ "${p}" = 'gpii-gcp-prd' ] || [ "${p}" = 'gpii-gcp-stg' ]; then
      echo gcloud -q --project "${p}" compute firewall-rules delete ${BAD_FW_RULES}
    else
      gcloud -q --project "${p}" compute firewall-rules delete ${BAD_FW_RULES}
    fi
  fi
done
