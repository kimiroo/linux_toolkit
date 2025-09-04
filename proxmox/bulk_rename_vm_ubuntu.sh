#!/bin/bash

read -p "Node ID: " NODE_ID_PREFIX

if [ "$NODE_ID_PREFIX" == "1" ]; then
    qm set 101 --name ubuntu-master-01 --tags "k3s-master,node-01"
    qm set 102 --name ubuntu-worker-01 --tags "k3s-worker,node-01"
    qm set 103 --name ubuntu-worker-02 --tags "k3s-worker,node-01"

elif [ "$NODE_ID_PREFIX" == "2" ]; then
    qm set 201 --name ubuntu-master-02 --tags "k3s-master,node-02"
    qm set 202 --name ubuntu-worker-03 --tags "k3s-worker,node-02"
    qm set 203 --name ubuntu-worker-04 --tags "k3s-worker,node-02"

elif [ "$NODE_ID_PREFIX" == "3" ]; then
    qm set 301 --name ubuntu-master-03 --tags "k3s-master,node-03"
    qm set 302 --name ubuntu-worker-05 --tags "k3s-worker,node-03"
    qm set 303 --name ubuntu-podman-01 --tags "podman,node-03" --cores 2 # Special config for Podman VM
fi

for vm_idx in 1 2 3
do
    VM_ID=$(printf "${NODE_ID_PREFIX}0${vm_idx}")
    echo "Starting VM $VM_ID..."
    qm start $VM_ID
done

echo "Done."