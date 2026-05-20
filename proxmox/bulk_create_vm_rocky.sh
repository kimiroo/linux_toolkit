#!/bin/bash

read -p "Template ID: " TEMPLATE_ID
read -p "Node ID: " NODE_ID_PREFIX
STORAGE="nvme-zfs"
CPUS=1
CORES=1
RAM=4096
GATEWAY="10.5.0.254"

declare -a CORES_LIST=(1 2) # master, worker
declare -a RAM_LIST=(4096 8192) # master, worker

for i in 1 2
do
    VM_ID="${NODE_ID_PREFIX}0${i}"
    VM_NAME=$(printf "rocky-node%02d-vm%02d" "$NODE_ID_PREFIX" "$i")
    VM_IP="10.5.47.${NODE_ID_PREFIX}${i}/16"
    CORES=${CORES_LIST[$((i-1))]}
    RAM=${RAM_LIST[$((i-1))]}

    echo "Creating VM $VM_NAME (ID: $VM_ID, RAM: ${RAM}MB)..."

    echo "Cloning template..."
    qm clone $TEMPLATE_ID $VM_ID --full --storage $STORAGE --name $VM_NAME --format raw

    echo "Configuring VM..."
    qm set $VM_ID --vcpus $CPUS --cores $CORES
    qm set $VM_ID --memory $RAM
    qm set $VM_ID --ipconfig0 ip=$VM_IP,gw=$GATEWAY
    qm set $VM_ID --onboot 1
done

echo "Done."