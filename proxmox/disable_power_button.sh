#!/bin/bash

# A script to set power-related key actions to "ignore" using a systemd drop-in file.

# Check for root privileges.
if [ "$EUID" -ne 0 ]; then
    echo "This script must be run as root."
    exit 1
fi

# Define the drop-in configuration file path.
CONFIG_DIRECTORY="/etc/systemd/logind.conf.d"
CONFIG_FILE="$CONFIG_DIRECTORY/90-ignore-power-keys.conf"

# Define the desired settings.
SETTINGS=(
    "HandlePowerKey=ignore"
    "HandlePowerKeyLongPress=ignore"
    "HandleRebootKey=ignore"
    "HandleRebootKeyLongPress=ignore"
    "HandleSuspendKey=ignore"
    "HandleSuspendKeyLongPress=ignore"
    "HandleHibernateKey=ignore"
    "HandleHibernateKeyLongPress=ignore"
    "HandleLidSwitch=ignore"
    "HandleLidSwitchExternalPower=ignore"
    "HandleLidSwitchDocked=ignore"
)

# Ensure the configuration directory exists.
echo "Creating config directory..."
mkdir -p "$CONFIG_DIRECTORY"

# Write the settings to the drop-in file.
echo "Creating drop-in configuration file..."
echo "[Login]" | tee "$CONFIG_FILE" > /dev/null
for setting in "${SETTINGS[@]}"; do
    echo "$setting" | tee -a "$CONFIG_FILE" > /dev/null
done

# Reload the systemd-logind service to apply the changes.
echo "Reloading systemd-logind service to apply changes..."
systemctl daemon-reload
systemctl restart systemd-logind.service

echo "Configuration has been applied."