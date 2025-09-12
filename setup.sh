#!/bin/bash

### Init Variables ###
ARCH="$(dpkg --print-architecture)"

KEYRING_DOCKER="/etc/apt/keyrings/docker.gpg"
KEYRING_KUBERNETES="/etc/apt/keyrings/kubernetes.gpg"
KEYRING_HELM="/etc/apt/keyrings/helm.gpg"

LISTFILE_DOCKER="/etc/apt/sources.list.d/docker.list"
LISTFILE_KUBERNETES="/etc/apt/sources.list.d/kubernetes.list"
LISTFILE_HELM="/etc/apt/sources.list.d/helm.list"


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
sudo rm -f "$KEYRING_KUBERNETES"
sudo rm -f "$KEYRING_HELM"

echo "[INFO] Setting up Docker keyrings..."
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o "$KEYRING_DOCKER"
sudo chmod 644 "$KEYRING_DOCKER"

echo "[INFO] Setting up Kubernetes keyrings..."
curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.33/deb/Release.key | sudo gpg --dearmor -o "$KEYRING_KUBERNETES"
sudo chmod 644 "$KEYRING_KUBERNETES"

echo "[INFO] Setting up Helm keyrings..."
curl -fsSL https://packages.buildkite.com/helm-linux/helm-debian/gpgkey | sudo gpg --dearmor -o "$KEYRING_HELM"
sudo chmod 644 "$KEYRING_HELM"
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

# Ubuntu & Debian
echo "[INFO] Setting up Kubernetes repository..."
echo \
    "deb [arch=$ARCH signed-by=$KEYRING_KUBERNETES] https://pkgs.k8s.io/core:/stable:/v1.33/deb/ \
    /" | \
    sudo tee "$LISTFILE_KUBERNETES" > /dev/null
sudo chmod 644 "$LISTFILE_KUBERNETES"

# Ubuntu & Debian
echo "[INFO] Setting up Helm repository..."
echo \
    "deb [arch=$ARCH signed-by=$KEYRING_HELM] https://packages.buildkite.com/helm-linux/helm-debian/any/ \
    any main" | \
    sudo tee "$LISTFILE_HELM" > /dev/null
sudo chmod 644 "$LISTFILE_HELM"
echo

### Install Packages ###
echo "[INFO] Clearing APT cache..."
sudo apt-get clean
echo

echo "[INFO] Updating APT cache..."
sudo apt-get update -y
echo

echo "[INFO] Uninstalling old packages..."
for pkg in docker.io docker-doc docker-compose docker-compose-v2 podman-docker containerd runc kubectl helm; do
    sudo apt-get remove $pkg;
done
echo

echo "[INFO] Installing packages..."
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin kubectl helm
echo

echo "[INFO] Done."
echo