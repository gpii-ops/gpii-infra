#!/bin/bash

#mount fast temporal local NVME disk
mkfs.ext4 /dev/disk/by-id/google-local-nvme-ssd-0
mkdir /local-ssd
mount /dev/disk/by-id/google-local-nvme-ssd-0 /local-ssd

# Extract hd images to files
# GCE connects the disks after the startup script runs
cd /dev/disk/by-id
for i in $(ls -1 scsi-0Google_PersistentDisk_pv-database-storage-couchdb-couchdb-* | rev | cut -d'_' -f1 | rev); do
    dd if=/dev/disk/by-id/scsi-0Google_PersistentDisk_$i | gzip > /local-ssd/$i.gz
done

ls -lha /local-ssd/

