#!/bin/bash

# Source: https://http.krfoss.org/pack/pve.sh

DEFAULT_ORIGIN="https://http.krfoss.org"
ORIGIN=""

# Function to display usage (help message)
usage() {
    echo "Usage: $0 [OPTIONS] [ORIGIN]"
    echo "Change Proxmox VE mirrorlists."
    echo ""
    echo "Options:"
    echo "  -o, --origin ORIGIN   Set the ORIGIN value."
    echo "                        (ORIGIN must be in following format: scheme://host[:port])"
    echo "  -h, --help            Display this help message and exit."
    echo ""
    echo "Examples:"
    echo "  $0 https://mirror.example.com"
    echo "  $0 -o https://mirror.example.com"
    echo "  $0 --origin https://mirror.example.com"
    echo "  $0"
    exit 0
}

# Function to validate the scheme of the ORIGIN
validate_origin() {
    local origin_str="$1"

    # Regex components for robust validation:
    # 1. Scheme: Common schemes used by apt (http, https, ftp, sftp, ssh, file, rsync)
    #    Note: 'file' scheme typically doesn't have host/port but regex will allow for simplicity.
    local scheme_regex="^(http|https|ftp|sftp|ssh|file|rsync)"

    # 2. Host: Domain name, IPv4, IPv6, or localhost
    #    IPv4: Basic 0-255.0-255.0-255.0-255
    #    IPv6: Simplified pattern, covers common bracketed forms.
    #          Full IPv6 regex is very complex, this is a practical approach.
    local ipv4_regex="(?:[0-9]{1,3}\.){3}[0-9]{1,3}"
    local ipv6_regex="\[[0-9a-fA-F:]+\]" # Covers common bracketed IPv6 (e.g., [::1], [2001:db8::1])
    local hostname_regex="([a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?\.)+[a-zA-Z]{2,6}|localhost"
    local host_regex="(${ipv4_regex}|${ipv6_regex}|${hostname_regex})"

    # 3. Port: Optional, colon followed by 0-65535.
    #    (?:...) is a non-capturing group. Bash regex does not support non-capturing groups
    #    in the same way as Perl-compatible regex. We'll simplify for bash.
    local port_regex="(:([0-9]|[1-9][0-9]{1,3}|[1-5][0-9]{4}|6[0-4][0-9]{3}|65[0-4][0-9]{2}|655[0-2][0-9]|6553[0-5]))?"

    # Combined regex pattern for the entire ORIGIN string
    # IMPORTANT: Bash regex uses backslashes for special characters that need to be escaped,
    # but often treats characters like '.', '?', '+' differently than PCRE.
    # For robustness, we often use extended regex syntax or simpler patterns.
    # For the `=~` operator, the string on the right side is treated as an extended regular expression.
    # We need to escape '.' and use proper grouping.
    local full_origin_regex="${scheme_regex}:\/\/${host_regex}${port_regex}$"

    # Perform the regex match
    if [[ "$origin_str" =~ $full_origin_regex ]]; then
        # Extracting parts using BASH_REMATCH array (bash 3.0+)
        # BASH_REMATCH[0] is the whole matched string
        # BASH_REMATCH[1] is the first captured group (scheme)
        # BASH_REMATCH[2] is the second captured group (host/IP)
        # BASH_REMATCH[3] is the third captured group (port if present, or empty)

        # Basic scheme validation against common apt schemes (redundant if regex is tight, but good check)
        local found_scheme="${BASH_REMATCH[1]}"
        if ! echo "$found_scheme" | grep -qE "^(http|https|ftp|sftp|ssh|file|rsync)$"; then
            echo "[ERROR] Invalid scheme '$found_scheme' detected in '$origin_str'." >&2
            return 1
        fi

        # Port validation if present
        local found_port="${BASH_REMATCH[4]}" # This depends on exact capturing groups, might need adjustment
                                                # For this simplified regex, port will be in BASH_REMATCH[4]
        if [ -n "$found_port" ]; then
            if ! (( found_port >= 0 && found_port <= 65535 )); then
                echo "[ERROR] Port '$found_port' is out of valid range (0-65535)." >&2
                return 1
            fi
        fi

        return 0 # Valid ORIGIN
    else
        echo "[ERROR] '$origin_str' does not match the expected ORIGIN format." >&2
        return 1 # Invalid ORIGIN
    fi
}

# Exit function
do_exit() {
    echo "[INFO] Exiting..."
    exit $1
}

# Use getopt to parse options
PARSED_ARGS=$(getopt -o o:h --long origin:,help -- "$@")

# Check if getopt encountered an error (e.g., invalid option)
if [ $? -ne 0 ]; then
    echo "Error: Invalid option or missing argument." >&2
    usage # Display usage and exit
fi

# Set positional parameters to the parsed arguments from getopt
eval set -- "$PARSED_ARGS"

# Process parsed options
while true; do
    case "$1" in
        -o|--origin)
            ORIGIN="$2" # Assign the argument value to ORIGIN
            shift 2     # Shift past the option and its argument
            ;;
        -h|--help)
            usage     # Call the usage function and exit
            ;;
        --)         # End of options marker
            shift     # Remove the -- from the arguments
            break     # Exit the while loop
            ;;
        *) # Should not happen with proper getopt usage, but good for robustness
            echo "Internal error: Unexpected option: $1" >&2
            exit 1
            ;;
    esac
done

# After getopt, check for a remaining positional argument
# If ORIGIN is still empty and there's a positional argument left, use it as ORIGIN
if [ -z "$ORIGIN" ] && [ -n "$1" ]; then
    ORIGIN="$1"
    shift # Remove the positional argument
fi

# If after all parsing, ORIGIN is still empty, use the default value
if [ -z "$ORIGIN" ]; then
    ORIGIN="$DEFAULT_ORIGIN"
    echo "[INFO] No ORIGIN specified. Using default ORIGIN: $ORIGIN"
fi

# Validate the ORIGIN scheme
#if ! validate_origin "$ORIGIN"; then
#    do_exit 1
#fi

# If there are any remaining arguments that were not processed, it's an error
#if [ -n "$@" ]; then
#    echo "[ERROR] Unrecognized arguments: $@" >&2
#    usage # Display usage and exit
#fi

# Check if script is running as root
if [ "$(id -u)" != "0" ]; then
    echo "[ERROR] This script must be run as root." >&2
    do_exit 1
fi

# Check if script is running in Proxmox VE
if ! dpkg -l | grep -q pve-manager; then
    echo "[ERROR] This script can only be run in a Proxmox VE environment." >&2
    do_exit 1
fi

# Check system information (codename detection)
codename=$(grep "VERSION_CODENAME=" /etc/os-release | cut -d= -f2 | tr -d '"')
if [ -z "$codename" ]; then
    # Try alternative method if failed to find codename
    if grep -q "bullseye" /etc/os-release; then
        codename="bullseye"
    elif grep -q "bookworm" /etc/os-release; then
        codename="bookworm"
    elif grep -q "trixie" /etc/os-release; then
        codename="trixie"
    else
        echo "[ERROR] Unsupported Debian version." >&2
        do_exit 1
    fi
fi
echo "[INFO] Detected Proxmox VE (Debian) version: $codename"

# Check Ceph version
ceph_version="squid"  # Default Ceph version (Proxmox 9.x trixie)
if pveversion -v | grep -E "^ceph:"; then
    ceph_version=$(pveversion -v | grep -E "^ceph:" | awk -F: '{print $2}' | awk -F- '{print $1}' | tr -d ' ')
    echo "[INFO] Detected Ceph version: $ceph_version"
fi

# Use default value if not found
if [ -z "$ceph_version" ]; then
    if [ "$codename" = "bookworm" ]; then
        ceph_version="reef"  # Proxmox 8.x (bookworm)'s default Ceph version
    elif [ "$codename" = "bullseye" ]; then
        ceph_version="pacific"  # Proxmox 7.x (bullseye)'s default Ceph version
    elif [ "$codename" = "trixie" ]; then
        ceph_version="squid"  # Proxmox 9.x (trixie)'s default Ceph version
    fi
    echo "[WARNING] Cannot detect Ceph version. Using default value for current Proxmox version ($codename): $ceph_version" >&2
fi

# Check if Proxmox VE is in beta/test version
IS_PVE_BETA=false
PVE_COMPONENTS="pve-no-subscription"
CEPH_COMPONENTS="no-subscription"
# Check if pve-manager version string contains '~'
# (Look for 'pve-manager/0.0.0~' pattern)
if pveversion | grep -qE "pve-manager/[0-9]+\.[0-9]+\.[0-9]+~"; then
    if [ $? -eq 0 ]; then
        IS_PVE_BETA=true
        PVE_COMPONENTS="pve-test"
        CEPH_COMPONENTS="test"
        echo "[INFO] Proxmox VE beta/test version detected. Using 'pve-test' PVE components and 'test' Ceph components."
    fi
fi

# Decide whether to use DEB822 format (on Debian 13 (trixie) or higher)
USE_DEB822_FORMAT=false
if [[ "$codename" == "trixie" || "$codename" > "trixie" ]]; then
    USE_DEB822_FORMAT=true
    echo "[INFO] Debian $codename detected. Using DEB822 format."
fi

# Make sure the directory exists
mkdir -p /etc/apt

# Global variable for checking if other sources list files exist
other_file_exists=false

if [ "$USE_DEB822_FORMAT" = true ]; then
    ### DEB822 FORMAT (trixie or higher) ###

    # DEB822 file paths
    DEBIAN_SOURCE_FILE="/etc/apt/sources.list.d/debian.sources"
    PROXMOX_SOURCE_FILE="/etc/apt/sources.list.d/proxmox.sources"
    CEPH_SOURCE_FILE="/etc/apt/sources.list.d/ceph.sources"

    # Keyring paths
    DEBIAN_KEYRING="/usr/share/keyrings/debian-archive-keyring.gpg"
    PVE_KEYRING_PATH="/etc/apt/trusted.gpg.d/proxmox-release-${codename}.gpg"

    declare -a MANAGED_DEB822_FILES=(
        "debian.sources"
        "proxmox.sources"
        "ceph.sources"
    )

    # Check Proxmox keyring file existence and warn if not found
    if [ ! -f "$PVE_KEYRING_PATH" ]; then
        echo "[WARNING] Cannot find Proxmox VE keyring file: '$PVE_KEYRING_PATH' Signature errors may occur during APT updates. You might need to manually import the key." >&2
    fi

    # Make sure the directory exists
    mkdir -p /etc/apt/sources.list.d

    # Deactivate existing sources.list
    if [ -f /etc/apt/sources.list ]; then
        echo "[INFO] Deactivating existing '/etc/apt/sources.list'..."
        BACKUP_FILE="/etc/apt/sources.list.bak.$(date +%Y%m%d)"
        cp /etc/apt/sources.list "$BACKUP_FILE"
        echo "[INFO] Renamed '/etc/apt/sources.list' to '$BACKUP_FILE'."
    fi

    # Rename existing .list and .sources files in /etc/apt/sources.list.d
    echo "[INFO] Backing up existing .list and .sources files in '/etc/apt/sources.list.d'..."
    for file in /etc/apt/sources.list.d/*.list /etc/apt/sources.list.d/*.sources; do
        if [ -f "$file" ]; then
            filename=$(basename "$file")

            # Check if the current file is in list of managed files
            is_managed_file=false
            for managed_deb822_name in "${MANAGED_DEB822_FILES[@]}"; do
                if [ "$filename" = "$managed_deb822_name" ]; then
                    is_managed_file=true
                    break
                fi
            done

            if [ "$is_managed_file" = true ]; then
                # If it's a file we manage, rename it (backup)
                BACKUP_LIST_FILE="/etc/apt/sources.list.d/.$(basename "$file").bak.$(date +%Y%m%d)"
                mv "$file" "$BACKUP_LIST_FILE"
                echo "[INFO] Renamed '$file' to '$BACKUP_LIST_FILE'."
            else
                # If it's NOT a file we manage, set the flag and warn
                other_file_exists=true
                echo "[WARNING] Found unmanaged APT repository file: '$file_path'. It has been left untouched." >&2
            fi
        fi
    done

    echo "[INFO] Generating sources.list files in DEB822 format..."
    # 1. Generate Debian base repository file (debian.sources)
    cat > "$DEBIAN_SOURCE_FILE" << EOF
Types: deb deb-src
URIs: $ORIGIN/debian/
Suites: $codename $codename-updates $codename-backports
Components: main contrib non-free non-free-firmware
Signed-By: $DEBIAN_KEYRING

Types: deb deb-src
URIs: $ORIGIN/debian-security/
Suites: $codename-security
Components: main contrib non-free non-free-firmware
Signed-By: $DEBIAN_KEYRING
EOF
    echo "[INFO] Generated '$DEBIAN_SOURCE_FILE'."

    # 2. Generate Proxmox VE repository file (proxmox.sources)
    cat > "$PROXMOX_SOURCE_FILE" << EOF
Types: deb
URIs: $ORIGIN/proxmox/debian/pve
Suites: $codename
Components: $PVE_COMPONENTS
Signed-By: $PVE_KEYRING_PATH
EOF
    echo "[INFO] Generated '$PROXMOX_SOURCE_FILE'."

    # 3. Generate Ceph repository file (ceph.sources)
    cat > "$CEPH_SOURCE_FILE" << EOF
Types: deb
URIs: $ORIGIN/proxmox/debian/ceph-$ceph_version
Suites: $codename
Components: $CEPH_COMPONENTS
Signed-By: $PVE_KEYRING_PATH
EOF
    echo "[INFO] Generated '$CEPH_SOURCE_FILE'."

else
    ### LEGACY FORMAT (below trixie) ###

    # Init
    SRC_LIST_FILE="/etc/apt/sources.list"
    BACKUP_FILE="$SRC_LIST_FILE.bak.$(date +%Y%m%d)"
    CEPH_LIST_FILE="/etc/apt/sources.list.d/ceph.list"
    CEPH_LIST_BACKUP_FILE="/etc/apt/sources.list.d/.ceph.list.bak.$(date +%Y%m%d)"

    IS_CEPH_ACTIVE=false
    if [ -f "$CEPH_LIST_FILE" ]; then
        IS_CEPH_ACTIVE=true
    fi

    # Backup existing sources.list
    echo "[INFO] Backing up existing .list files..."

    mv "$SRC_LIST_FILE" "$BACKUP_FILE"
    echo "[INFO] Renamed '$SRC_LIST_FILE' to '$BACKUP_FILE'."

    if [ "$IS_CEPH_ACTIVE" = true ]; then
        mv "$CEPH_LIST_FILE" "$CEPH_LIST_BACKUP_FILE"
        echo "[INFO] Renamed '$CEPH_LIST_FILE' to '$CEPH_LIST_BACKUP_FILE'."
    fi

    # Check if unmanaged files exist
    for file in /etc/apt/sources.list.d/*.list; do
        if [ -f "$file" ] && [ "$(basename "$file")" != "ceph.list" ]; then
            other_file_exists=false
            echo "[WARNING] Found unmanaged APT repository file: '$file' in '/etc/apt/sources.list.d/*.list'. It has been left untouched." >&2
        fi
    done

    echo "[INFO] Generating sources.list files in legacy sources.list format..."

    # Generate new sources.list
    cat > "$SRC_LIST_FILE" << EOF
deb $ORIGIN/debian $codename main contrib

deb $ORIGIN/debian $codename-updates main contrib

deb $ORIGIN/proxmox/debian/pve $codename $PVE_COMPONENTS

# security updates
deb $ORIGIN/debian-security/ $codename-security main contrib
EOF
    echo "[INFO] Generated '$SRC_LIST_FILE'."

    # Generate new ceph.list
    if [ "$IS_CEPH_ACTIVE" = true ]; then
        cat > "$CEPH_LIST_FILE" << EOF
deb $ORIGIN/proxmox/debian/ceph-$ceph_version $codename $CEPH_COMPONENTS
EOF
        echo "[INFO] Generated '$CEPH_LIST_FILE'."
    fi
fi

# Final warning if other files were found
if [ "$other_file_exists" = true ]; then
    echo ""
    echo "[WARNING] It appears there are other APT repository files in '/etc/apt/sources.list.d/'" >&2
    echo "          that this script does not manage. Please review these files manually." >&2
    echo ""
fi

# Clear and update APT cache
echo "[INFO] Clearing APT cache..."
apt-get clean
echo "[INFO] Updating APT cache..."
apt-get update

echo "[INFO] Updated all supported APT repositories to use '$ORIGIN' mirror."
do_exit 0