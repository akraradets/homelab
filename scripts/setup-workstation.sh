#!/usr/bin/env bash
# ==============================================================================
# Essential Workstation Setup: SSH, QEMU Agent, TrueNAS Mount & Docker
# Target: Ubuntu (VM 110 : work-desktop / VM 120 : work-compute)
# 1:1 Path Parity with TrueNAS: /mnt/pool-1/home
# ==============================================================================

set -euo pipefail

TRUENAS_IP="192.168.55.100"
TRUENAS_HOME_EXPORT="/mnt/pool-1/home"
LOCAL_HOME_MOUNT="/mnt/pool-1/home"

echo "=========================================================="
echo " Starting Essential Workstation Setup on $(hostname)"
echo "=========================================================="

# Ensure running as root
if [[ $EUID -ne 0 ]]; then
   echo "Error: This script must be run with sudo or as root."
   exit 1
fi

export DEBIAN_FRONTEND=noninteractive

# ------------------------------------------------------------------------------
# 1. OpenSSH Server & QEMU Guest Agent
# ------------------------------------------------------------------------------
echo "==> [1/3] Installing & enabling OpenSSH Server and QEMU Guest Agent..."
apt-get update -y
apt-get install -y --no-install-recommends \
    openssh-server \
    qemu-guest-agent \
    ca-certificates \
    curl \
    gnupg

systemctl enable --now ssh
systemctl enable --now qemu-guest-agent

# ------------------------------------------------------------------------------
# 2. NFS Client & TrueNAS Mount (1:1 Path Parity: /mnt/pool-1/home)
# ------------------------------------------------------------------------------
echo "==> [2/3] Installing NFS client and mounting TrueNAS storage..."
apt-get install -y --no-install-recommends nfs-common

# Create mount point matching TrueNAS exact path
mkdir -p "${LOCAL_HOME_MOUNT}"

# Configure /etc/fstab for TrueNAS home
FSTAB_HOME="${TRUENAS_IP}:${TRUENAS_HOME_EXPORT} ${LOCAL_HOME_MOUNT} nfs defaults,_netdev,bg,intr,noatime,nfsvers=4 0 0"

if ! grep -q "${TRUENAS_HOME_EXPORT}" /etc/fstab; then
    echo "Adding TrueNAS home mount to /etc/fstab..."
    echo "${FSTAB_HOME}" >> /etc/fstab
fi

# Attempt mount
echo "Mounting TrueNAS storage..."
mount "${LOCAL_HOME_MOUNT}" || echo "Notice: Home NFS mount pending TrueNAS export activation"

# ------------------------------------------------------------------------------
# 3. Docker CE & Docker Compose Plugin
# ------------------------------------------------------------------------------
echo "==> [3/3] Installing official Docker CE & Compose plugin..."
install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
chmod a+r /etc/apt/keyrings/docker.asc

echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "${UBUNTU_CODENAME:-$VERSION_CODENAME}") stable" | \
  tee /etc/apt/sources.list.d/docker.list > /dev/null

apt-get update -y
apt-get install -y --no-install-recommends \
    docker-ce \
    docker-ce-cli \
    containerd.io \
    docker-buildx-plugin \
    docker-compose-plugin

systemctl enable --now docker

# If run via sudo, add the calling user to docker group
if [[ -n "${SUDO_USER:-}" ]] && [[ "${SUDO_USER}" != "root" ]]; then
    usermod -aG docker "${SUDO_USER}"
    echo "Added user ${SUDO_USER} to docker group."
fi

echo "=========================================================="
echo " Essential Workstation Setup Completed!"
echo " - SSH Service:     active"
echo " - QEMU Agent:      active"
echo " - TrueNAS Storage: ${LOCAL_HOME_MOUNT} (Mounts user vaults & projects)"
echo " - Docker Version:  $(docker --version)"
echo "=========================================================="
