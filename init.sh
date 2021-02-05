#/bin/bash
set -e

PROJECT_ID=$(gcloud config get-value core/project)
CLUSTER_NAME="${PROJECT_ID}"
CLUSTER_ZONE=asia-northeast3-c

NODE_ROTATOR_SERVICE_ACCOUNT_NAME="${CLUSTER_NAME}-node-rotator-sa"
DATA_ACCESS_SERVICE_ACCOUNT_NAME="${CLUSTER_NAME}-data-access-sa"
GCS_BUCKET_NAME="${CLUSTER_NAME}"

gcloud config set compute/zone $CLUSTER_ZONE

gcloud services enable container.googleapis.com

if [ -z "$(gsutil ls)" ] || [ -z "$(gsutil ls | grep $GCS_BUCKET_NAME)" ]; then
  gsutil mb -l ASIA-NORTHEAST3 gs://${GCS_BUCKET_NAME}/
else 
  echo "skip bucket creation '$GCS_BUCKET_NAME' already exists"
fi

if [ -z "$(gcloud iam service-accounts list --filter $DATA_ACCESS_SERVICE_ACCOUNT_NAME)" ]; then
  gcloud iam service-accounts create ${DATA_ACCESS_SERVICE_ACCOUNT_NAME} --display-name="CG Data Access Service Account"
  gcloud iam service-accounts keys create --iam-account "${DATA_ACCESS_SERVICE_ACCOUNT_NAME}@${PROJECT_ID}.iam.gserviceaccount.com" data-access-service-account.json
else
  echo "skip sa creation '${DATA_ACCESS_SERVICE_ACCOUNT_NAME}' already exists"
fi
gsutil iam ch serviceAccount:${DATA_ACCESS_SERVICE_ACCOUNT_NAME}@${PROJECT_ID}.iam.gserviceaccount.com:objectAdmin gs://${GCS_BUCKET_NAME}/

if [ -z "$(gcloud beta container clusters list --filter NAME=$CLUSTER_NAME)" ]; then
  gcloud beta container clusters create $CLUSTER_NAME \
    --cluster-version latest \
    --machine-type n1-standard-1 \
    --enable-autoscaling \
    --num-nodes 1 \
    --min-nodes 1 \
    --max-nodes 3 \
    --disk-size 32GB \
    --enable-ip-alias
else
  echo "skip cluster creation '$CLUSTER_NAME' already exists"
fi

NODE_POOL_NAME=crawler-pool
if [ -z "$(gcloud container node-pools list --filter NAME=$NODE_POOL_NAME --cluster $CLUSTER_NAME)" ]; then
  gcloud container node-pools create $NODE_POOL_NAME \
    --cluster $CLUSTER_NAME \
    --zone $CLUSTER_ZONE \
    --scopes cloud-platform \
    --enable-autoupgrade \
    --preemptible \
    --disk-size 10GB \
    --num-nodes 0 --machine-type n1-standard-1 \
    --enable-autoscaling --min-nodes=0 --max-nodes=10
else
  echo "skip node-pool creation '$NODE_POOL_NAME' already exists"
fi

NODE_POOL_NAME=etl-pool
if [ -z "$(gcloud container node-pools list --filter NAME=$NODE_POOL_NAME --cluster $CLUSTER_NAME)" ]; then
  gcloud container node-pools create $NODE_POOL_NAME \
    --cluster $CLUSTER_NAME \
    --zone $CLUSTER_ZONE \
    --scopes cloud-platform \
    --enable-autoupgrade \
    --preemptible \
    --disk-size 10GB \
    --num-nodes 0 --machine-type e2-medium \
    --enable-autoscaling --min-nodes=0 --max-nodes=10
else
  echo "skip node-pool creation '$NODE_POOL_NAME' already exists"
fi
