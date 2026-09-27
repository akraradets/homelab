# NetBird Remote Access & Subnet Routing

This runbook documents the secure, zero-inbound-port remote access mesh configured for the homelab using **NetBird Cloud**.

---

## 1. Overview & Architecture

- **Control Plane**: NetBird Cloud ([app.netbird.io](https://app.netbird.io))
- **Data Plane**: WireGuard P2P direct encrypted tunnels
- **Inbound Router Ports**: **Zero** (no port forwarding, NAT traversal via STUN/TURN/ICE)
- **Routing Peer**: Bare-metal **Proxmox VE Host (`pve-1`)**
- **Forwarded Subnet**: `192.168.55.0/24` (Masquerade / NAT enabled)

```mermaid
graph TD
    subgraph Remote["Remote Client (Anywhere)"]
        MacBook["MacBook Pro\nNetBird Client"]
    end

    subgraph Internet["Public Internet"]
        NBCloud["NetBird Cloud\nSignaling & Auth"]
    end

    subgraph HomeLab["Home Network (Zero Open Ports)"]
        Router["ISP Home Router\nFirewall: All Inbound Blocked"]
        
        subgraph PVE["Proxmox Host (pve-1)"]
            PVE_Host["PVE Hypervisor\nNetBird Daemon (wt0)\nSubnet Router (192.168.55.10)"]
            Bridge["Linux Bridge vmbr0\n(192.168.55.0/24)"]
        end

        subgraph Storage["TrueNAS SCALE VM (ID: 100)"]
            TrueNAS["TrueNAS SCALE\nIP: 192.168.55.100\nSMB, NFS, Web GUI (:443)"]
        end

        subgraph Compute["Client Workloads"]
            Workstations["Desktop & Dev VMs\n(192.168.55.110 - .120)"]
        end
    end

    MacBook <-.->|Control / Signaling| NBCloud
    PVE_Host <-.->|Control / Signaling| NBCloud
    MacBook == Direct WireGuard P2P Tunnel ==> PVE_Host
    PVE_Host -->|IP Forwarding| Bridge
    Bridge --> TrueNAS
    Bridge --> Workstations
```

---

## 2. Host Configuration on Proxmox VE (`pve-1`)

### A. IP Forwarding
Configured in `/etc/sysctl.d/99-netbird.conf`:
```text
net.ipv4.ip_forward = 1
```

### B. Client Service
NetBird runs as a systemd service managed by `systemctl`:
```bash
# Check status
systemctl status netbird

# Status & peer connections
netbird status
```

---

## 3. NetBird Cloud Network Route Configuration

In **[app.netbird.io](https://app.netbird.io)** $\rightarrow$ **Network Routes**:
- **Network ID**: `homelab-subnet`
- **Network Range**: `192.168.55.0/24`
- **Routing Peer**: `pve-1`
- **Masquerade**: Enabled (Checked)
- **Distribution Groups**: `All` (or your user/admin group)

---

## 4. Verification & Testing

From your MacBook outside the home network:
1. Connect to NetBird in the macOS menu bar app.
2. Access services via their private FQDN:
   - **Proxmox VE**: `https://pve-1.home.sinsamersuk.net:8006`
   - **TrueNAS SCALE**: `https://truenas.home.sinsamersuk.net`
   - **SSH**: `ssh root@192.168.55.10`
   - **SMB / Time Machine**: `smb://truenas.home.sinsamersuk.net`
