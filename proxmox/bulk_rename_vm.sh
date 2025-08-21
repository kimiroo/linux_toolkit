#!/bin/bash

NODE_ID_PREFIX=1

if [ "$NODE_ID_PREFIX" == "1" ]; then
    qm set 101 --name rocky-master01
    qm set 102 --name rocky-worker01
    qm set 103 --name rocky-docker01

    qm set 101 --tags "k3s-master,node01"
    qm set 102 --tags "k3s-worker,node01"
    qm set 103 --tags "docker,node01"

    qm set 103 --cores 2 # Special config for Docker VM

elif [ "$NODE_ID_PREFIX" == "2" ]; then
    qm set 201 --name rocky-master02
    qm set 202 --name rocky-worker02
    qm set 203 --name rocky-worker03

    qm set 201 --tags "k3s-master,node02"
    qm set 202 --tags "k3s-worker,node02"
    qm set 203 --tags "k3s-worker,node02"

elif [ "$NODE_ID_PREFIX" == "3" ]; then
    qm set 301 --name rocky-master03
    qm set 302 --name rocky-worker04
    qm set 303 --name rocky-worker05

    qm set 301 --tags "k3s-master,node03"
    qm set 302 --tags "k3s-worker,node03"
    qm set 303 --tags "k3s-worker,node03"
fi

for vm_idx in 1 2 3
do
    VM_ID=$(printf "${NODE_ID_PREFIX}0${vm_idx}")
    echo "Starting VM $VM_ID..."
    qm start $VM_ID
done

echo "Done."