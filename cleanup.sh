#/bin/bash
set -e

PROJECT_ID=$(gcloud config get-value core/project)
CLUSTER_NAME="comm-game"
CLUSTER_ZONE=asia-northeast3-c


SERVICE_ACCOUNT_NAME="${CLUSTER_NAME}-data-access-sa"
GCS_BUCKET_NAME="datalake-${CLUSTER_NAME}"

gcloud config set compute/zone $CLUSTER_ZONE

gcloud beta container clusters delete $CLUSTER_NAME 

