#!/usr/bin/env bash

rke etcd snapshot-save --name snapshot.db
sudo cp -rf /opt/rke/etcd-snapshots/snapshot.db.zip cluster_backup_start/snapshot.db.zip
sudo chmod +rw cluster_backup_start/snapshot.db.zip