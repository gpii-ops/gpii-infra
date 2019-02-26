# This resource is needed to restore PVs that were previously claimed by CouchDB
# We need it to avoid data loss during forceful cluster re-creation
# https://issues.gpii.net/browse/GPII-3493

resource "null_resource" "couchdb_recover_pvcs" {
  count = "${var.execute_recover_pvcs == "true" ? 1 : 0}"

  triggers = {
    nonce = "${var.nonce}"
  }

  provisioner "local-exec" {
    command = <<EOF
      for DISK in $(gcloud compute disks list --filter description:couchdb --format json | jq -c .[]); do
        PD_NAME=$(echo $DISK | jq -r .name)
        PD_DESC=$(echo $DISK | jq -r .description)
        PV_NAME=$(echo $PD_DESC | jq -r '.["kubernetes.io/created-for/pv/name"]')
        PVC_NAME=$(echo $PD_DESC | jq -r '.["kubernetes.io/created-for/pvc/name"]')
        if [ "$(kubectl -n gpii get pvc $PVC_NAME -o json 2>/dev/null | jq -r .metadata.name)" != "$PVC_NAME" ]; then
          jq -n \
            --arg pd_name "$PD_NAME" \
            --arg pv_name "$PV_NAME" \
            --arg pvc_name "$PVC_NAME" \
          '{
            "apiVersion": "v1",
            "items": [
              {
                "apiVersion": "v1",
                "kind": "Namespace",
                "metadata": {
                  "name": "${var.release_namespace}",
                }
              },
              {
                "apiVersion": "v1",
                "kind": "PersistentVolume",
                "metadata": {
                  "name": $pv_name
                },
                "spec": {
                  "accessModes": [
                    "ReadWriteOnce"
                  ],
                  "capacity": {
                    "storage": "${var.pv_capacity}"
                  },
                  "gcePersistentDisk": {
                    "fsType": "ext4",
                    "pdName": $pd_name
                  },
                  "persistentVolumeReclaimPolicy": "${var.pv_reclaim_policy}",
                  "storageClassName": "${var.pv_storage_class}"
                }
              },
              {
                "apiVersion": "v1",
                "kind": "PersistentVolumeClaim",
                "metadata": {
                  "labels": {
                    "app": "couchdb",
                    "release": "couchdb"
                  },
                  "name": $pvc_name,
                  "namespace": "${var.release_namespace}",
                },
                "spec": {
                  "accessModes": [
                    "ReadWriteOnce"
                  ],
                  "resources": {
                    "requests": {
                      "storage": "${var.pv_capacity}"
                    }
                  },
                  "storageClassName": "${var.pv_storage_class}",
                  "volumeName": $pv_name
                }
              }
            ],
          "kind": "List"}' | kubectl apply -f -
        fi
      done
    EOF
  }
}
