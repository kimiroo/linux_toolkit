#!/bin/bash

# SSH security settings
declare -A SETTINGS
SETTINGS["PubkeyAuthentication"]="yes"
SETTINGS["PasswordAuthentication"]="no"
SETTINGS["PermitEmptyPasswords"]="no"
SETTINGS["PermitRootLogin"]="prohibit-password"
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
done
