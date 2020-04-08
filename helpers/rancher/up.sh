#!/usr/bin/env bash

if [[ -z "${RANCHER_HOST}" ]]; then
	echo "Please define RANCHER_HOST env var"
	exit 1
fi

# create cluster
rke up

# save config
mkdir -p cluster_backup_start
cp -rf cluster.yml cluster_backup_start/cluster.yml
cp -rf kube_config_cluster.yml cluster_backup_start/kube_config_cluster.yml
cp -rf cluster.rkestate cluster_backup_start/cluster.rkestate

export KUBECONFIG=kube_config_cluster.yml

helm repo update

if [[ -z "$(helm repo list | grep jetstack)" ]]; then
	# **Important:**
	# If you are running Kubernetes v1.15 or below, you
	# will need to add the `--validate=false` flag to your
	# kubectl apply command, or else you will receive a
	# validation error relating to the
	# x-kubernetes-preserve-unknown-fields field in
	# cert-manager’s CustomResourceDefinition resources.
	# This is a benign error and occurs due to the way kubectl
	# performs resource validation.

	# Add the Jetstack Helm repository
	helm repo add jetstack https://charts.jetstack.io
fi

if [[ -z "$(kubectl get namespaces | grep cert-manager)" ]]; then
	# Install the CustomResourceDefinition resources separately
	kubectl apply -f https://raw.githubusercontent.com/jetstack/cert-manager/release-0.12/deploy/manifests/00-crds.yaml
fi

# Create the namespace for cert-manager
kubectl create namespace cert-manager

# Update your local Helm chart repository cache
helm repo update

# Install the cert-manager Helm chart
helm install \
  cert-manager jetstack/cert-manager \
  --namespace cert-manager \
  --version v0.12.0

kubectl -n cert-manager rollout status deployment/cert-manager
kubectl -n cert-manager rollout status deployment/cert-manager-cainjector
kubectl -n cert-manager rollout status deployment/cert-manager-webhook

if [[ -z "$(helm repo list | grep rancher-stable )" ]]; then
	helm repo add rancher-stable https://releases.rancher.com/server-charts/stable
fi

helm repo update

kubectl create namespace cattle-system
helm install rancher rancher-stable/rancher \
  --namespace cattle-system \
  --set ingress.tls.source=rancher \
  --set hostname=${RANCHER_HOST}

kubectl -n cattle-system rollout status deploy/rancher
