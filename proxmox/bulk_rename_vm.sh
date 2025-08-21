#!/bin/bash

read -p "Node ID: " NODE_ID_PREFIX

if [ "$NODE_ID_PREFIX" == "1" ]; then
    qm set 101 --name rocky-master-01 --tags "k3s-master,node-01"
    qm set 102 --name rocky-worker-01 --tags "k3s-worker,node-01"
    qm set 103 --name rocky-worker-02 --tags "k3s-worker,node-01"

elif [ "$NODE_ID_PREFIX" == "2" ]; then
    qm set 201 --name rocky-master-02 --tags "k3s-master,node-02"
    qm set 202 --name rocky-worker-03 --tags "k3s-worker,node-02"
    qm set 203 --name rocky-worker-04 --tags "k3s-worker,node-02"

elif [ "$NODE_ID_PREFIX" == "3" ]; then
    qm set 301 --name rocky-master-03 --tags "k3s-master,node-03"
    qm set 302 --name rocky-worker-05 --tags "k3s-worker,node-03"
    qm set 303 --name rocky-podman-01 --tags "podman,node-03" --cores 2 # Special config for Podman VM
fi

for vm_idx in 1 2 3
do
    VM_ID=$(printf "${NODE_ID_PREFIX}0${vm_idx}")
    echo "Starting VM $VM_ID..."
    qm start $VM_ID
done

echo "Done."