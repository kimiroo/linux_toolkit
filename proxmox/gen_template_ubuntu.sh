#!/bin/bash

# Image URL
IMAGE_URL="https://ftp.kaist.ac.kr/ubuntu-cloud-image/noble/current/noble-server-cloudimg-amd64.img"
# Image path
IMAGE="/var/tmp/Ubuntu-CloudImage.qcow2"
# Template ID
read -p "Template ID: " TEMPLATE_ID
# Template name
TEMPLATE_NAME=Ubuntu-24.04-Template
# Disk size
SIZE=20G
# Network bridge
BRIDGE=vmbr0
# RAM
RAM=2048
# CPU cores
CORES=1
# Storage pool
STORAGE=local-zfs
# Cloud Init user
read -p "User: " USER
# Cloud Init user password
read -sp "Password: " PASSWORD
echo ""
read -sp "Confirm password: " PASSWORD_CHK
echo ""
# SSH Public key
read -p "Public key: " PUB_KEY

if [ "$PASSWORD" != "$PASSWORD_CHK" ]; then
    echo "Passwords do not match. Exiting."
    exit 1
fi


# --- Step 1: Download and customize the cloud image ---
# Download image
echo "Downloading cloud image..."
wget $IMAGE_URL -O $IMAGE

# Generate script file to harden sshd_config
echo "Generating temporary sshd configuration script..."
printf '#!/bin/bash

# SSH security settings
declare -A SETTINGS
SETTINGS["PubkeyAuthentication"]="yes"
SETTINGS["PasswordAuthentication"]="no"
SETTINGS["PermitEmptyPasswords"]="no"
SETTINGS["PermitRootLogin"]="no"
SETTINGS["AllowUsers"]="%s"
SETTINGS["MaxAuthTries"]="3"
SETTINGS["LoginGraceTime"]="60"
SETTINGS["ClientAliveInterval"]="300"
SETTINGS["ClientAliveCountMax"]="0"
SETTINGS["MaxStartups"]="10"
SETTINGS["AllowTcpForwarding"]="no"
SETTINGS["X11Forwarding"]="no"
SETTINGS["AllowAgentForwarding"]="no"
SETTINGS["Protocol"]="2"
SETTINGS["UseDNS"]="no"
SETTINGS["PrintMotd"]="no"
SETTINGS["TCPKeepAlive"]="yes"
SETTINGS["KexAlgorithms"]="curve25519-sha256,curve25519-sha256@libssh.org,diffie-hellman-group16-sha512,diffie-hellman-group18-sha512,diffie-hellman-group14-sha256"
SETTINGS["Ciphers"]="chacha20-poly1305@openssh.com,aes256-gcm@openssh.com,aes128-gcm@openssh.com,aes256-ctr,aes192-ctr,aes128-ctr"
SETTINGS["MACs"]="umac-128-etm@openssh.com,hmac-sha2-256-etm@openssh.com,hmac-sha2-512-etm@openssh.com,umac-128@openssh.com,hmac-sha2-256,hmac-sha2-512"

CONFIG_FILE="/etc/ssh/sshd_config"

# Backup original file
cp "$CONFIG_FILE" "${CONFIG_FILE}.orig"

# Update each setting
for setting in "${!SETTINGS[@]}"; do
    value="${SETTINGS[$setting]}"

    # Check if setting exists (commented or uncommented)
    if grep -q "^#\{0,1\}${setting}[ \t]" "$CONFIG_FILE"; then
        # Update existing line
        sed -i "s/^#\{0,1\}${setting}.*/${setting} ${value}/" "$CONFIG_FILE"
    else
        # Add new setting
        echo "${setting} ${value}" >> "$CONFIG_FILE"
    fi
done\n' "$USER" > "/var/tmp/sshd_config.sh"

# Customize image
echo "Customizing cloud image with virt-customize..."
virt-customize -a $IMAGE \
    --timezone "Asia/Seoul" \
    --install vim,wget,curl,qemu-guest-agent,intel-microcode,chrony \
    --upload /var/tmp/sshd_config.sh:/var/tmp/sshd_config.sh \
    --run-command 'systemctl enable qemu-guest-agent' \
    --run-command 'bash /var/tmp/sshd_config.sh' \
    --run-command 'rm -f /var/tmp/sshd_config.sh' \
    --run-command "sed -i.ori '/pool ntp.ubuntu.com/i\server time.kriss.re.kr iburst\nserver time2.kriss.re.kr iburst\n' /etc/chrony/chrony.conf" \
    --run-command "mkdir -p /etc/systemd/system/getty@ttyS0.service.d" \
    --run-command "printf '[Service]\nExecStart=\nExecStart=-/sbin/agetty -o '\''-- \\\\u'\'' --keep-baud 115200,57600,38400,9600 - \${TERM}\n' | sudo tee /etc/systemd/system/getty@ttyS0.service.d/override.conf" \
    --run-command "sudo sed -i 's#http://\(archive\|security\)\.ubuntu\.com#https://mirror.kakao.com#g' /etc/apt/sources.list.d/ubuntu.sources" \
    --run-command 'cloud-init clean' \
    --run-command 'truncate -s 0 /etc/machine-id' \
    --run-command 'rm -rf /var/lib/cloud/instances/*' \
    --run-command 'rm -rf /var/lib/cloud/instance' \
    --run-command 'rm -rf /var/log/cloud-init*' \
    --run-command 'truncate -s 0 /var/log/wtmp' \
    --run-command 'truncate -s 0 /var/log/lastlog' \
    --run-command 'rm -f /etc/ssh/ssh_host_*' \
    --run-command 'rm -rf /root/.ssh/known_hosts' \
    --run-command 'rm -rf /home/*/.ssh/known_hosts' \
    --firstboot-command 'timedatectl set-ntp no' \
    --firstboot-command 'systemctl enable chrony' \
    --firstboot-command 'systemctl start chrony'

# Resize image
echo "Resizing image..."
qemu-img resize $IMAGE $SIZE


# --- Step 2: Create the VM and import the disk ---
# Create VM
echo "Creating VM..."
qm create $TEMPLATE_ID \
    --name $TEMPLATE_NAME \
    --memory $RAM \
    --cores $CORES \
    --net0 virtio,bridge=$BRIDGE \
    --machine q35 \
    --bios ovmf \
    --scsihw virtio-scsi-single \
    --cpu host

# Import image
echo "Importing image into a storage pool..."
qm importdisk $TEMPLATE_ID $IMAGE $STORAGE

echo "Attaching imported disk to the VM..."
if [ "$STORAGE" == "local" ]; then
    qm set $TEMPLATE_ID --virtio0 $STORAGE:$TEMPLATE_ID/vm-$TEMPLATE_ID-disk-0.raw
else
    qm set $TEMPLATE_ID --virtio0 $STORAGE:vm-$TEMPLATE_ID-disk-0,discard=on,iothread=1
fi


# --- Step 3: Configure Cloud-Init and finalize VM settings ---
echo "Configuring Cloud-Init and other VM options..."
# Enable QEMU guest agent
qm set $TEMPLATE_ID --agent 1

# Change boot order to start with VirtIO block device
qm set $TEMPLATE_ID --boot c --bootdisk virtio0

# Attach cloud init image
qm set $TEMPLATE_ID --ide2 $STORAGE:cloudinit

# Inject SSH key
echo "$PUB_KEY" > /var/tmp/pubkey
qm set $TEMPLATE_ID --sshkey /var/tmp/pubkey

# Set default IP assignment to DHCP, and update username and password.
qm set $TEMPLATE_ID --ciuser=$USER --cipassword="$PASSWORD" --ipconfig0 ip=dhcp

# Create and attach EFI disk
qm set $TEMPLATE_ID --efidisk0 $STORAGE:1,format=raw,efitype=4m,pre-enrolled-keys=1

# Attach serial port to the VM
qm set $TEMPLATE_ID -serial0 socket


# --- Step 4: Convert the VM to a template and clean up ---
# Convert to a template
echo "Converting VM to a template..."
qm template $TEMPLATE_ID

# Cleanup
echo "Cleaning up temporary files..."
rm -f $IMAGE
rm -f /var/tmp/sshd_config.sh
rm -f /var/tmp/pubkey

echo "Script completed successfully."