#!/bin/bash
#

# gcloud implementation

INSTANCE_NAME=$1
PROJECT=$2

if [ "$#" -ne 2 ]; then
  echo "$0 INSTANCE_NAME GCP_PROJECT"
  echo "  Plese provide name of instance to query and gcp project within which it resides."
  exit 1
fi

# Find the zone for the instance
ZONE=$(gcloud compute instances list --filter="${INSTANCE_NAME}" --format='value(ZONE)')

# get metadata 
gcloud compute instances describe ${INSTANCE_NAME} \
  --format='json(metadata.items)' \
  --zone ${ZONE} \
  --project ${PROJECT}
