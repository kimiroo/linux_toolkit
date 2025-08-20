#!/bin/bash

TEMPLATE_ID=9100
NODE_ID_PREFIX=1
STORAGE="nvme-zfs"
CPUS=1
CORES=1
RAM=2048
GATEWAY="10.5.37.254"

for i in 1 2 3
do
    VM_ID="${NODE_ID_PREFIX}0${i}"
    VM_NAME=$(printf "rocky-node%02d-vm%02d" "$NODE_ID_PREFIX" "$i")
    VM_IP="10.5.47.${NODE_ID_PREFIX}${i}/16"

    echo "Creating VM $VM_NAME (ID: $VM_ID)..."

    echo "Cloning template..."
    qm clone $TEMPLATE_ID $VM_ID --full --storage $STORAGE --name $VM_NAME --format qcow2

    echo "Configuring VM..."
    qm set $VM_ID --vcpus $CPUS --cores $CORES
    qm set $VM_ID --memory $RAM
    qm set $VM_ID --ipconfig0 ip=$VM_IP,gw=$GATEWAY
    qm set $VM_ID --onboot 1

    echo "Starting VM..."
    qm start $VM_ID
done

echo "Done."