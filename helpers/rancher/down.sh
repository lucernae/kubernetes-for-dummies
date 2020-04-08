#!/usr/bin/env bash

mkdir -p cluster_backup

# kubeconfig backup
cp -rf rancher-cluster.yml cluster_backup/cluster.yml
cp -rf kube_config_cluster.yml cluster_backup/kube_config_cluster.yml
cp -tg cluster.rkestate cluster_backup/cluster.rkestate

# etcd snapshot
rke etcd snapshot-save --name snapshot.db
sudo cp -rf /opt/rke/etcd-snapshots/snapshot.db.zip cluster_backup/snapshot.db.zip
sudo chmod +rw cluster_backup/snapshot.db.zip

# delete rancher
system-tools remove --kubeconfig kube_config_cluster.yml

# drain node
kubectl drain "$NODE"

# remove cluster
rke remove

# cleanup docker
docker stop $(docker ps -a | grep k8s | awk '{print $1}')
docker rm $(docker ps -a | grep k8s | awk '{print $1}')