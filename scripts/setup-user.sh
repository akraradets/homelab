#!/usr/bin/env bash
# ==============================================================================
# Workstation User Setup: Interactive User & UID:GID Configuration
# Target: Ubuntu Desktop / Server (VM 110 / VM 120)
# ==============================================================================

set -euo pipefail

# 1. Ensure running as root
if [[ $EUID -ne 0 ]]; then
    echo "Error: This script must be run with sudo or as root."
    exit 1
fi

echo "=========================================================="
echo " Workstation User Account Setup"
echo "=========================================================="

# 2. Prompt for username (or accept as argument $1)
if [[ $# -ge 1 ]] && [[ -n "${1:-}" ]]; then
    TARGET_USER="$1"
else
    read -rp "Enter username [akraradets]: " INPUT_USER
    TARGET_USER="${INPUT_USER:-akraradets}"
fi

# 3. Prompt for UID:GID (or accept as argument $2)
if [[ $# -ge 2 ]] && [[ -n "${2:-}" ]]; then
    INPUT_ID="$2"
else
    read -rp "Enter UID:GID [3000:3000]: " INPUT_ID
    INPUT_ID="${INPUT_ID:-3000:3000}"
fi

# Parse UID:GID format (e.g. 3000:3000 or single 3000)
if [[ "${INPUT_ID}" == *":"* ]]; then
    TARGET_UID="${INPUT_ID%%:*}"
    TARGET_GID="${INPUT_ID##*:}"
else
    TARGET_UID="${INPUT_ID}"
    TARGET_GID="${INPUT_ID}"
fi

# Input validation
if ! [[ "${TARGET_UID}" =~ ^[0-9]+$ ]] || ! [[ "${TARGET_GID}" =~ ^[0-9]+$ ]]; then
    echo "Error: UID and GID must be valid positive integers (got '${INPUT_ID}')."
    exit 1
fi

if ! [[ "${TARGET_USER}" =~ ^[a-z_][a-z0-9_-]*[$]?$ ]]; then
    echo "Error: Invalid Linux username '${TARGET_USER}'."
    exit 1
fi

LOCAL_HOME="/home/${TARGET_USER}"

echo ""
echo "Configuring user '${TARGET_USER}' (UID: ${TARGET_UID}, GID: ${TARGET_GID})..."
echo "Local home: ${LOCAL_HOME}"
echo "----------------------------------------------------------"

# 4. Check if user already exists
if id "${TARGET_USER}" &>/dev/null; then
    CURRENT_UID=$(id -u "${TARGET_USER}")
    CURRENT_GID=$(id -g "${TARGET_USER}")
    echo "User '${TARGET_USER}' already exists (UID: ${CURRENT_UID}, GID: ${CURRENT_GID})."

    if [[ "${CURRENT_UID}" -ne "${TARGET_UID}" ]] || [[ "${CURRENT_GID}" -ne "${TARGET_GID}" ]]; then
        echo "Updating UID to ${TARGET_UID} and GID to ${TARGET_GID}..."
        
        # Check if user has active running processes
        if pgrep -u "${TARGET_USER}" >/dev/null; then
            echo ""
            echo "ERROR: Cannot change UID while user '${TARGET_USER}' is logged in or has active processes."
            echo "Please log in as another administrative user or root, or terminate user processes with:"
            echo "  sudo pkill -u ${TARGET_USER}"
            echo "Then re-run this script."
            exit 1
        fi

        # Ensure target GID group exists
        if ! getent group "${TARGET_GID}" >/dev/null; then
            groupmod -g "${TARGET_GID}" "${TARGET_USER}" 2>/dev/null || groupadd -g "${TARGET_GID}" "${TARGET_USER}"
        fi

        usermod -u "${TARGET_UID}" -g "${TARGET_GID}" "${TARGET_USER}"
        chown -R "${TARGET_UID}:${TARGET_GID}" "${LOCAL_HOME}"
        echo "Successfully updated '${TARGET_USER}' to UID ${TARGET_UID} and GID ${TARGET_GID}."
    else
        echo "UID and GID already match ${TARGET_UID}:${TARGET_GID}. No ID change needed."
    fi
else
    echo "Creating group '${TARGET_USER}' (GID: ${TARGET_GID})..."
    if ! getent group "${TARGET_GID}" >/dev/null; then
        groupadd -g "${TARGET_GID}" "${TARGET_USER}"
    fi

    echo "Creating user '${TARGET_USER}' (UID: ${TARGET_UID}, GID: ${TARGET_GID})..."
    useradd -u "${TARGET_UID}" -g "${TARGET_GID}" -m -s /bin/bash "${TARGET_USER}"
    echo "User '${TARGET_USER}' created."
fi

# 5. Add to necessary groups
GROUPS_TO_ADD=()
for grp in sudo docker video render input audio kvm; do
    if getent group "${grp}" >/dev/null; then
        GROUPS_TO_ADD+=("${grp}")
    fi
done

if [[ ${#GROUPS_TO_ADD[@]} -gt 0 ]]; then
    JOINED_GROUPS=$(IFS=, ; echo "${GROUPS_TO_ADD[*]}")
    echo "Adding '${TARGET_USER}' to groups: ${JOINED_GROUPS}..."
    usermod -aG "${JOINED_GROUPS}" "${TARGET_USER}"
fi

# 6. Configure Passwordless Sudo
echo "Configuring passwordless sudo in /etc/sudoers.d/${TARGET_USER}..."
SUDOER_FILE="/etc/sudoers.d/${TARGET_USER}"
echo "${TARGET_USER} ALL=(ALL) NOPASSWD:ALL" > "${SUDOER_FILE}"
chmod 0440 "${SUDOER_FILE}"
visudo -cf "${SUDOER_FILE}" >/dev/null || {
    echo "Error: Generated sudoers file failed syntax check!"
    rm -f "${SUDOER_FILE}"
    exit 1
}

# 7. Ensure local home ownership
chown -R "${TARGET_UID}:${TARGET_GID}" "${LOCAL_HOME}"

# 8. Password Setup Check / Reminder
if passwd -S "${TARGET_USER}" | grep -q " P "; then
    echo "Password is already set for '${TARGET_USER}'."
else
    echo ""
    echo "Notice: User '${TARGET_USER}' currently has NO password set."
    echo "If you need a password for desktop GUI / screen lock, set one using:"
    echo "  sudo passwd ${TARGET_USER}"
fi

echo ""
echo "=========================================================="
echo " Setup complete for user '${TARGET_USER}'!"
echo " - UID/GID:         $(id -u "${TARGET_USER}") / $(id -g "${TARGET_USER}")"
echo " - Groups:          $(id -Gn "${TARGET_USER}")"
echo " - Local Home:      ${LOCAL_HOME}"
echo " - Sudo Privileges: Passwordless (/etc/sudoers.d/${TARGET_USER})"
echo "=========================================================="
echo ""
echo "To link TrueNAS storage vault (/mnt/pool-1/home/${TARGET_USER}), run:"
echo "----------------------------------------------------------"
echo "# Step 1: Initialize vault directory on TrueNAS storage:"
echo "sudo mkdir -p /mnt/pool-1/home/${TARGET_USER}/.ssh"
echo "sudo mkdir -p /mnt/pool-1/home/${TARGET_USER}/projects"
echo "sudo chown -R ${TARGET_UID}:${TARGET_GID} /mnt/pool-1/home/${TARGET_USER}"
echo "sudo chmod 700 /mnt/pool-1/home/${TARGET_USER}/.ssh"
echo ""
echo "# Step 2: (Optional) Copy over current SSH authorized_keys if present:"
echo "sudo cp ~/.ssh/authorized_keys /mnt/pool-1/home/${TARGET_USER}/.ssh/ 2>/dev/null || true"
echo "sudo chown ${TARGET_UID}:${TARGET_GID} /mnt/pool-1/home/${TARGET_USER}/.ssh/authorized_keys 2>/dev/null || true"
echo "sudo chmod 600 /mnt/pool-1/home/${TARGET_USER}/.ssh/authorized_keys 2>/dev/null || true"
echo ""
echo "# Step 3: Symlink into local home (run as user ${TARGET_USER}):"
echo "ln -sfn /mnt/pool-1/home/${TARGET_USER}/.ssh ~/.ssh"
echo "ln -sfn /mnt/pool-1/home/${TARGET_USER}/projects ~/projects"
echo "----------------------------------------------------------"
