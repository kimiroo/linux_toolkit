#!/bin/bash

read -p "Template ID: " TEMPLATE_ID
read -p "Node ID: " NODE_ID_PREFIX
STORAGE="nvme-zfs"
CPUS=1
CORES=1
RAM=4096
GATEWAY="10.5.0.254"

declare -a RAM_SIZES=(2048 4096 4096) #master, worker, worker or docker

for i in 1 2 3
do
    VM_ID="${NODE_ID_PREFIX}0${i}"
    VM_NAME=$(printf "ubuntu-node%02d-vm%02d" "$NODE_ID_PREFIX" "$i")
    VM_IP="10.5.47.${NODE_ID_PREFIX}${i}/16"
    RAM=${RAM_SIZES[$((i-1))]}

    echo "Creating VM $VM_NAME (ID: $VM_ID, RAM: ${RAM}MB)..."

    echo "Cloning template..."
    qm clone $TEMPLATE_ID $VM_ID --full --storage $STORAGE --name $VM_NAME --format qcow2

    echo "Configuring VM..."
    qm set $VM_ID --vcpus $CPUS --cores $CORES
    qm set $VM_ID --memory $RAM
    qm set $VM_ID --ipconfig0 ip=$VM_IP,gw=$GATEWAY
    qm set $VM_ID --onboot 1
done

#for i in 1 2 3
#do
#    VM_ID="${NODE_ID_PREFIX}0${i}"
#    VM_NAME=$(printf "rocky-node%02d-vm%02d" "$NODE_ID_PREFIX" "$i")
#
#    echo "Starting VM $VM_NAME (ID: $VM_ID)..."
#    qm start $VM_ID
#done

echo "Done."