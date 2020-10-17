#!/bin/bash
#
set -e
set -o nounset

INSTANCE_NAME=$(curl -H "Metadata-Flavor: Google" http://169.254.169.254/computeMetadata/v1/instance/name)
ZONE=$(curl -H "Metadata-Flavor: Google" http://169.254.169.254/computeMetadata/v1/instance/zone | awk -F"/" '{print $NF}')
DISK_NAME=$(curl -H "Metadata-Flavor: Google" http://169.254.169.254/computeMetadata/v1/instance/attributes/disk_name)
PRIVATE_IP=$(curl -H "Metadata-Flavor: Google" http://169.254.169.254/computeMetadata/v1/instance/network-interfaces/0/ip)
ENVNAME=$(curl -H "Metadata-Flavor: Google" http://169.254.169.254/computeMetadata/v1/instance/attributes/envname)
DOMAIN=$(curl -H "Metadata-Flavor: Google" http://169.254.169.254/computeMetadata/v1/instance/attributes/domain)
DISK_MOUNT=/nfs

# Attach regional disk
gcloud compute disks describe ${DISK_NAME} \
  --region ${ZONE%-*} \
  --format='value(users)' | \
  grep -q "${INSTANCE_NAME}" || \
  gcloud compute instances attach-disk ${INSTANCE_NAME} \
    --disk ${DISK_NAME} \
    --disk-scope regional \
    --force-attach \
    --mode rw \
    --zone ${ZONE}

# disk partition, format and mount
fdisk -l | grep sdb1 || \
  echo '/dev/sdb1: start=2048, Id=83' | sfdisk /dev/sdb

file -sL /dev/sdb1 |  grep "ext4 filesystem" || \
  mkfs.ext4 /dev/sdb1

mkdir -p ${DISK_MOUNT}
mountpoint -q ${DISK_MOUNT} || mount /dev/sdb1 ${DISK_MOUNT}
chmod 777 ${DISK_MOUNT}

# NFS server install
apt-get install -y nfs-kernel-server

# configure shares
>/etc/exports
mkdir -p ${DISK_MOUNT}/wordpress
echo "${DISK_MOUNT}/wordpress     *(rw,no_root_squash,subtree_check)" >> /etc/exports

systemctl restart nfs-kernel-server

# Set DNS
DNS_NAME="nfs.${DOMAIN}"

DNS_ZONE=$(gcloud dns managed-zones list --filter="${DOMAIN}" --format='value(NAME)')
DNS_TTL=60
DNS_TYPE=A
TRANS_FILE=/tmp/transaction.yaml

[ -e "${TRANS_FILE}" ] && rm -f ${TRANS_FILE}

DNS_IP=$(gcloud dns record-sets list \
  --zone=${DNS_ZONE} \
  --name=${DNS_NAME} \
  --format='value(DATA)') || DNS_IP=""

if [ "${DNS_IP}" != "${PRIVATE_IP}" ]
then
  gcloud dns record-sets transaction start \
    --zone ${DNS_ZONE} \
    --transaction-file ${TRANS_FILE}
  if [ "${DNS_IP}" != "" ]
  then
    gcloud dns record-sets transaction remove ${DNS_IP} \
      --name ${DNS_NAME} \
      --ttl ${DNS_TTL} \
      --type ${DNS_TYPE} \
      --zone ${DNS_ZONE} \
      --transaction-file ${TRANS_FILE}
  fi
  gcloud dns record-sets transaction add ${PRIVATE_IP} \
    --name ${DNS_NAME} \
    --ttl ${DNS_TTL} \
    --type ${DNS_TYPE} \
    --zone ${DNS_ZONE} \
    --transaction-file ${TRANS_FILE}
  gcloud dns record-sets transaction execute \
    --zone ${DNS_ZONE} \
    --transaction-file ${TRANS_FILE}
  rm -f ${TRANS_FILE}
fi




