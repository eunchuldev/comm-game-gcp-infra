#/bin/bash
set -e

CLUSTER_NAME="comm-game"

kubectl scale --replicas=0 deployment/kube-dns-autoscaler --namespace=kube-system
kubectl scale --replicas=1 deployment/kube-dns --namespace=kube-system

gcloud beta container clusters update $CLUSTER_NAME \
  --autoscaling-profile optimize-utilization
