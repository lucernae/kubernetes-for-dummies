#!/usr/bin/env bash

rke etcd snapshot-restore --name snapshot.db --config cluster-restore.yml
rke up --config cluster-restore.yml