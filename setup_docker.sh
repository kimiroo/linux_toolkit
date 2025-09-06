#!/bin/bash

### Init Variables ###
ARCH="$(dpkg --print-architecture)"
KEYRING_DOCKER="/etc/apt/keyrings/docker.gpg"
LISTFILE_DOCKER="/etc/apt/sources.list.d/docker.list"


### Prepare System ###
echo "[INFO] Updating APT cache..."
sudo apt-get update
echo

echo "[INFO] Installing required packges..."
sudo apt-get install -y curl ca-certificates apt-transport-https gnupg
echo

### Setup Keyrings ###
echo "[INFO] ======== Setting up keyrings ========"
echo "[INFO] Initializing keyrings..."
sudo install -m 0755 -d /etc/apt/keyrings
sudo rm -f "$KEYRING_DOCKER"

echo "[INFO] Setting up Docker keyrings..."
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o "$KEYRING_DOCKER"
sudo chmod 644 "$KEYRING_DOCKER"
echo

### Setup Repositories ###
echo "[INFO] ======== Setting up repositories ========"
# Ubuntu Only
echo "[INFO] Setting up Docker repository..."
echo \
    "deb [arch=$ARCH signed-by=$KEYRING_DOCKER] https://download.docker.com/linux/ubuntu \
    $(. /etc/os-release && echo "${UBUNTU_CODENAME:-$VERSION_CODENAME}") stable" | \
    sudo tee "$LISTFILE_DOCKER" > /dev/null
sudo chmod 644 "$LISTFILE_DOCKER"
echo

### Install Packages ###
echo "[INFO] Clearing APT cache..."
sudo apt-get clean
echo

echo "[INFO] Updating APT cache..."
sudo apt-get update -y
echo

echo "[INFO] Uninstalling old packages..."
for pkg in docker.io docker-doc docker-compose docker-compose-v2 podman-docker containerd runc; do
    sudo apt-get remove $pkg;
done
echo

echo "[INFO] Installing packages..."
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
echo

echo "[INFO] Done."
echo