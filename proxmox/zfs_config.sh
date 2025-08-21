#!/bin/bash

# A script to set ZFS ARC max/min options and reboot the system.

# Check if the script is run as root.
if [ "$EUID" -ne 0 ]; then
    echo "This script must be run as root."
    exit 1
fi

# Define ZFS ARC values in bytes.
ZFS_ARC_MAX="1610612736" # 1.5 GiB
ZFS_ARC_MIN="536870912"  # 0.5 GiB

# Set the ZFS ARC max and min values.
echo "options zfs zfs_arc_max=${ZFS_ARC_MAX}" | tee /etc/modprobe.d/zfs.conf
echo "options zfs zfs_arc_min=${ZFS_ARC_MIN}" | tee -a /etc/modprobe.d/zfs.conf

# Update initramfs for all kernels.
echo "Updating initramfs for all kernels..."
update-initramfs -u -k all

# Check if the update was successful.
if [ $? -eq 0 ]; then
    echo "Initramfs update successful. Rebooting now..."
    # The system will be rebooted if initramfs update is successful.
    shutdown -r now
else
    echo "Failed to update initramfs. Aborting reboot."
    exit 1
fi