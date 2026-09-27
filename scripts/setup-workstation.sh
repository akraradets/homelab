#!/usr/bin/env bash
# ==============================================================================
# Workstation Automated Setup: RDP, Docker, NFS /etc/fstab, VS Code & Identity
# Target: Ubuntu 24.04 LTS (VM 110 : work-desktop)
# ==============================================================================

set -euo pipefail

TARGET_USER="akraradets"
TARGET_UID="3000"
TARGET_GID="3000"
TRUENAS_IP="192.168.55.100"
TRUENAS_PROJECTS_EXPORT="/mnt/pool-1/projects/akraradets"
LOCAL_MOUNT_POINT="/home/${TARGET_USER}/projects"

echo "=========================================================="
echo " Starting Workstation Automated Setup on $(hostname)"
echo "=========================================================="

# Ensure running as root
if [[ $EUID -ne 0 ]]; then
   echo "Error: This script must be run with sudo or as root."
   exit 1
fi

export DEBIAN_FRONTEND=noninteractive

# ------------------------------------------------------------------------------
# 1. Align User Identity (UID 3000, GID 3000) & SSH Permissions
# ------------------------------------------------------------------------------
echo "==> [1/6] Aligning user ${TARGET_USER} identity to UID ${TARGET_UID}, GID ${TARGET_GID}..."

# Update GID
if getent group "${TARGET_USER}" >/dev/null; then
    groupmod -g "${TARGET_GID}" "${TARGET_USER}" || true
else
    groupadd -g "${TARGET_GID}" "${TARGET_USER}"
fi

# Update UID
usermod -u "${TARGET_UID}" -g "${TARGET_GID}" "${TARGET_USER}" || true

# Add to sudo group
usermod -aG sudo "${TARGET_USER}"

# Ensure sudoers does not prompt for password (homelab workstation convenience)
echo "${TARGET_USER} ALL=(ALL) NOPASSWD:ALL" > "/etc/sudoers.d/99-${TARGET_USER}-nopasswd"
chmod 440 "/etc/sudoers.d/99-${TARGET_USER}-nopasswd"

# Fix home directory and SSH permissions (fixes OpenSSH StrictModes rejection)
mkdir -p "/home/${TARGET_USER}/.ssh"
chmod 750 "/home/${TARGET_USER}"
chmod 700 "/home/${TARGET_USER}/.ssh"
if [[ -f "/home/${TARGET_USER}/.ssh/authorized_keys" ]]; then
    chmod 600 "/home/${TARGET_USER}/.ssh/authorized_keys"
fi
chown -R "${TARGET_UID}:${TARGET_GID}" "/home/${TARGET_USER}"

# ------------------------------------------------------------------------------
# 2. Disable XDG Directory Bloat (Keep $HOME Clean)
# ------------------------------------------------------------------------------
echo "==> [2/6] Disabling XDG user directory auto-creation..."
mkdir -p /etc/xdg
cat << 'EOF' > /etc/xdg/user-dirs.conf
enabled=False
EOF

# ------------------------------------------------------------------------------
# 3. Base Updates & NFS Client (/etc/fstab)
# ------------------------------------------------------------------------------
echo "==> [3/6] Installing NFS utilities and configuring /etc/fstab..."
apt-get update -y
apt-get install -y --no-install-recommends \
    nfs-common \
    curl \
    wget \
    gnupg \
    ca-certificates \
    git \
    tmux \
    htop \
    build-essential \
    net-tools

# Create mount directory
mkdir -p "${LOCAL_MOUNT_POINT}"
chown "${TARGET_UID}:${TARGET_GID}" "${LOCAL_MOUNT_POINT}"

# Configure /etc/fstab for TrueNAS projects share
FSTAB_LINE="${TRUENAS_IP}:${TRUENAS_PROJECTS_EXPORT} ${LOCAL_MOUNT_POINT} nfs defaults,_netdev,bg,intr,noatime 0 0"

if ! grep -q "${TRUENAS_PROJECTS_EXPORT}" /etc/fstab; then
    echo "Adding TrueNAS NFS mount to /etc/fstab..."
    echo "${FSTAB_LINE}" >> /etc/fstab
fi

# Attempt mount
echo "Mounting ${LOCAL_MOUNT_POINT}..."
mount "${LOCAL_MOUNT_POINT}" || echo "Warning: NFS mount failed (verify TrueNAS pool-1 NFS export is active)"

# ------------------------------------------------------------------------------
# 4. Install Docker CE & Docker Compose
# ------------------------------------------------------------------------------
echo "==> [4/6] Installing official Docker CE & Docker Compose plugin..."
install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
chmod a+r /etc/apt/keyrings/docker.asc

echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "${UBUNTU_CODENAME:-$VERSION_CODENAME}") stable" | \
  tee /etc/apt/sources.list.d/docker.list > /dev/null

apt-get update -y
apt-get install -y \
    docker-ce \
    docker-ce-cli \
    containerd.io \
    docker-buildx-plugin \
    docker-compose-plugin

# Add user to docker group
usermod -aG docker "${TARGET_USER}"
systemctl enable --now docker

# ------------------------------------------------------------------------------
# 5. Install Desktop Environment & XRDP (RDP Server)
# ------------------------------------------------------------------------------
echo "==> [5/6] Installing Ubuntu GNOME Minimal, XRDP, and Polkit rules..."
apt-get install -y --no-install-recommends \
    ubuntu-desktop-minimal \
    xrdp \
    xorgxrdp

# Grant xrdp user access to ssl certificates
adduser xrdp ssl-cert || true

# Disable Wayland in GDM to force X11 compatibility
if [[ -f /etc/gdm3/custom.conf ]]; then
    sed -i 's/^#WaylandEnable=false/WaylandEnable=false/' /etc/gdm3/custom.conf
fi

# Prevent Polkit authorization popups on RDP login (colord / NetworkManager)
mkdir -p /etc/polkit-1/rules.d
cat << 'EOF' > /etc/polkit-1/rules.d/02-allow-colord.rules
polkit.addRule(function(action, subject) {
    if ((action.id == "org.freedesktop.color-manager.create-device" ||
         action.id == "org.freedesktop.color-manager.create-profile" ||
         action.id == "org.freedesktop.color-manager.delete-device" ||
         action.id == "org.freedesktop.color-manager.delete-profile" ||
         action.id == "org.freedesktop.color-manager.modify-device" ||
         action.id == "org.freedesktop.color-manager.modify-profile") &&
        subject.isInGroup("sudo")) {
        return polkit.Result.YES;
    }
});
EOF

cat << 'EOF' > /etc/polkit-1/rules.d/03-allow-networkmanager.rules
polkit.addRule(function(action, subject) {
    if (action.id.indexOf("org.freedesktop.NetworkManager.") == 0 && subject.isInGroup("sudo")) {
        return polkit.Result.YES;
    }
});
EOF

# Ensure user starts standard GNOME session on RDP connect
cat << 'EOF' > "/home/${TARGET_USER}/.xsessionrc"
export GNOME_SHELL_SESSION_MODE=ubuntu
export XDG_CURRENT_DESKTOP=ubuntu:GNOME
export XDG_CONFIG_DIRS=/etc/xdg/xdg-ubuntu:/etc/xdg
EOF
chown "${TARGET_UID}:${TARGET_GID}" "/home/${TARGET_USER}/.xsessionrc"

# Restart XRDP services so the daemon picks up the ssl-cert group membership
systemctl daemon-reload
systemctl restart xrdp xrdp-sesman
systemctl enable xrdp xrdp-sesman

# ------------------------------------------------------------------------------
# 6. Install Official Microsoft VS Code
# ------------------------------------------------------------------------------
echo "==> [6/6] Installing Microsoft Visual Studio Code..."
curl -fsSL https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor -o /etc/apt/keyrings/packages.microsoft.gpg
chmod a+r /etc/apt/keyrings/packages.microsoft.gpg

echo "deb [arch=amd64 signed-by=/etc/apt/keyrings/packages.microsoft.gpg] https://packages.microsoft.com/repos/code stable main" | \
  tee /etc/apt/sources.list.d/vscode.list > /dev/null

apt-get update -y
apt-get install -y code

echo "=========================================================="
echo " Workstation Setup Successfully Completed!"
echo " - Desktop RDP:     192.168.55.110:3389"
echo " - Docker Version:  $(docker --version)"
echo " - User:            ${TARGET_USER} (UID ${TARGET_UID}, GID ${TARGET_GID})"
echo " - Projects Mount:  ${LOCAL_MOUNT_POINT}"
echo "=========================================================="
