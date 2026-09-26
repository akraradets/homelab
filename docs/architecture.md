# Homelab Architecture

This document describes the complete infrastructure architecture of the homelab, spanning Google Cloud Platform (DNS & IaC state), NetBird Cloud (zero-trust remote access), and a consolidated Proxmox VE hypervisor running a virtualized TrueNAS SCALE appliance.

```mermaid
flowchart TD
    subgraph GCP ["Google Cloud Platform (Project: sinsamersuk)"]
        CloudDNS["Cloud DNS\n• Zone: sinsamersuk.net\n• Public & Internal Records\n• DNSSEC Enabled"]
        GCS["Cloud Storage Bucket\n• sinsamersuk-homelab-tfstate\n• Terraform Remote State"]
        SA["Service Accounts\n• terraform-admin (IaC Automation)\n• pve-acme (DNS-01 Challenge)"]
    end

    subgraph RemoteAccess ["Remote Access (Zero Inbound Ports)"]
        NetBirdCloud["NetBird Cloud (app.netbird.io)\n• Free Managed Control Plane\n• WireGuard Signaling & SSO\n• Outbound-only Handshakes"]
        MacClient["MacBook / Mobile Client\n(NetBird Client Installed)"]
    end

    subgraph PhysicalHost ["Physical Server (Proxmox VE Host: pve-1)"]
        PVE["Proxmox VE 8.x Hypervisor\nIP: 192.168.55.10\nHost FQDN: pve-1.home.sinsamersuk.net\nRouting Peer for NetBird (192.168.55.0/24)\nACME Client (Let's Encrypt SSL via Cloud DNS)"]

        subgraph VMBR ["Virtual Switch Fabric (vmbr0)"]
            VMLink["Host RAM Bridge (~15-25+ Gbps Near-Memory Speeds)"]
        end

        subgraph VMs ["Virtual Machines"]
            TrueNAS["TrueNAS SCALE VM (ID: 100)\nIP: 192.168.55.100\n• 4 vCPUs / 16GB Dedicated RAM\n• 32GB Virtual NVMe Boot Disk\n• Manages ZFS Pools & Datasets\n• Serves SMB & Apple Time Machine"]
            WorkDesktop["Workstation Desktop VM\n• SPICE Display + qemu-vdagent\n• Fluid Cursor & Clipboard Sync\n• Mounts TrueNAS over vmbr0"]
            WorkHeadless["Headless Dev VM\n• Docker & Background Jobs\n• Mounts TrueNAS over vmbr0"]
        end

        subgraph HardwareDrives ["Physical Storage Hardware"]
            SATA["Motherboard SATA / SAS HBA Controller\n(Direct PCIe Passthrough via IOMMU)"]
            Disks["Physical Hard Drives\n(Raw ZFS Health & SMART Monitoring)"]
        end
    end

    %% Storage connections
    SATA ==>|PCIe Passthrough| TrueNAS
    Disks --- SATA

    %% Network & Interconnect
    PVE --- VMBR
    VMBR <===> TrueNAS
    VMBR <===> WorkDesktop
    VMBR <===> WorkHeadless

    %% Remote Access connections
    MacClient -.->|Signaling| NetBirdCloud
    PVE -.->|Signaling| NetBirdCloud
    MacClient ===>|Direct WireGuard P2P Tunnel| PVE
    PVE -->|Subnet Routing 192.168.55.0/24| TrueNAS

    %% Cloud DNS & ACME
    CloudDNS -.->|Resolves pve-1.home.sinsamersuk.net| PVE
    PVE ==>|ACME DNS-01 Challenge (TXT record)| CloudDNS
```

---

## 1. Cloud Infrastructure (Google Cloud Platform)

All cloud resources are provisioned declaratively via Terraform in [`terraform/gcp/`](../terraform/gcp):

- **GCP Project**: `sinsamersuk`
- **Domain & DNS**:
  - Authoritative public DNS zone: `sinsamersuk-net` managing `sinsamersuk.net.`.
  - DNSSEC enabled for cryptographic integrity.
  - Internal homelab endpoints resolve under the `home.sinsamersuk.net.` subdomain.
- **Remote State Storage**:
  - GCS Bucket: `gs://sinsamersuk-homelab-tfstate/terraform/state/gcp/default.tfstate`.
  - Encrypted at rest, versioning enabled for state rollback protection.
- **Security & Multi-Account Isolation**:
  - Controlled by a dedicated Service Account: `terraform-admin@sinsamersuk.iam.gserviceaccount.com`.
  - Roles bound: `roles/dns.admin`, `roles/storage.admin`, and `roles/iam.serviceAccountKeyAdmin`.
  - Local key file [`terraform/gcp/credentials.json`](../terraform/gcp/credentials.json) is strictly git-ignored, ensuring Terraform operations never collide with global `gcloud` accounts.
- **ACME Service Account**:
  - Dedicated SA: `pve-acme@sinsamersuk.iam.gserviceaccount.com`.
  - Roles bound: `roles/dns.admin` (allows creating and removing ACME TXT verification records in Cloud DNS).
  - Private key exported to [`terraform/gcp/pve-acme-sa.json`](../terraform/gcp/pve-acme-sa.json) (git-ignored) for deployment to Proxmox VE.

---

## 2. Remote Access: NetBird Cloud

Remote administration uses **NetBird Cloud** ([app.netbird.io](https://app.netbird.io)) to eliminate inbound port-forwarding and protect residential IP privacy:

- **Zero Open Router Ports**: Both clients and home servers connect outbound to NetBird's signaling servers. Your home router remains invisible to internet port scanners.
- **Subnet Routing**: The Proxmox host (`192.168.55.10`) acts as a **Routing Peer** forwarding the `192.168.55.0/24` subnet.
- **Direct WireGuard P2P**: Data traffic between your MacBook and homelab servers is encrypted end-to-end via WireGuard.
- **Dynamic IP Resilience**: When your residential ISP rotates your public IP, the NetBird daemon automatically renegotiates peer tunnels in seconds with zero downtime.

---

## 3. Internal Addressing & DNS Hierarchy

| FQDN / Hostname | Internal IP | Role / Service |
| :--- | :--- | :--- |
| `pve-1.home.sinsamersuk.net` | `192.168.55.10` | Proxmox VE Web Management GUI (`:8006`) & SSH |
| `truenas.home.sinsamersuk.net` | `192.168.55.100` | TrueNAS SCALE Web GUI (`:443`), SMB, NFS |
| `work-desktop.home.sinsamersuk.net` | `192.168.55.110` | Desktop Workstation VM (SPICE / Remote Desktop) |
| `work-dev.home.sinsamersuk.net` | `192.168.55.120` | Headless Development VM (Docker & Pipelines) |

---

## 4. Single-Host Compute & Storage Architecture

Rather than running multiple power-hungry physical servers connected over a slow 1 Gbps physical switch, all compute and storage workloads are consolidated onto a single bare-metal host.

### Hypervisor: Proxmox VE 8.x (`pve-1`)
- Installed bare-metal on internal NVMe/SSD storage.
- IOMMU (`intel_iommu=on` or `amd_iommu=on`) and VFIO kernel modules enabled for hardware passthrough.

### Storage Appliance: TrueNAS SCALE VM (`vm_id = 100`)
- **Direct PCIe Passthrough (`hostpci`)**: The motherboard SATA controller or SAS HBA is passed directly to TrueNAS. TrueNAS talks directly to bare-metal hard drives for S.M.A.R.T. health diagnostics and ZFS scrub integrity.
- **OS Boot Drive**: Dedicated 32 GB virtual disk on NVMe (`local-lvm`) using VirtIO SCSI.
- **Memory**: 16 GB dedicated fixed RAM (memory ballooning disabled for ZFS stability).
- **Apple Time Machine**: Dedicated ZFS dataset (`tank/backups/timemachine`) exported via SMB with strict quotas to prevent backups from overfilling the pool.

### High-Speed Inter-VM Interconnect (`vmbr0`)
- Compute VMs and TrueNAS connect over the internal Linux bridge (`vmbr0`) using `virtio-net`.
- Network traffic between Workstation VMs and TrueNAS storage travels entirely within host RAM, achieving **sustained speeds of ~15–25+ Gbps** without requiring physical 10GbE network cards or switches.

### Workstation Desktop VM
- Features a **SPICE** display driver (`qxl`) with `qemu-vdagent` installed inside the guest.
- Provides smooth mouse cursor tracking, automatic resolution resizing to match browser/client windows, and seamless clipboard copy/paste.

---

## 5. Automated SSL Certificates (Let's Encrypt via DNS-01 Challenge)

Because the homelab resides entirely behind a firewall with no inbound ports forwarded, conventional HTTP-01 validation (port 80) cannot be used. Instead, Proxmox VE is configured with ACME DNS-01 validation against Google Cloud DNS:

1. **Service Account**: `pve-acme@sinsamersuk.iam.gserviceaccount.com` has permissions (`roles/dns.admin`) to provision and remove DNS TXT records.
2. **Credential Deployment**:
   - The generated key [`pve-acme-sa.json`](../terraform/gcp/pve-acme-sa.json) is copied to the Proxmox host:
     ```bash
     scp terraform/gcp/pve-acme-sa.json root@192.168.55.10:/etc/pve/priv/acme/gcp.json
     ssh root@192.168.55.10 "chmod 600 /etc/pve/priv/acme/gcp.json"
     ```
3. **Proxmox ACME Plugin Configuration**:
   - In PVE Web GUI -> **Datacenter** -> **ACME** -> **Challenge Plugins** -> **Add**:
     - **Plugin ID**: `gcp-dns`
     - **DNS API**: `Google Cloud DNS (gcloud)`
     - **API Data**:
       ```text
       GCLOUD_PROJECT=sinsamersuk
       GCLOUD_KEY_FILE=/etc/pve/priv/acme/gcp.json
       ```
4. **Certificate Issuance**:
   - In PVE Web GUI -> **pve-1** -> **Certificates** -> **ACME** -> **Add**:
     - **Domain**: `pve-1.home.sinsamersuk.net`
     - **Challenge Type**: `DNS`
     - **Plugin**: `gcp-dns`
   - Click **Order Certificates Now**. Proxmox creates the `_acme-challenge.pve-1.home.sinsamersuk.net` TXT record in Cloud DNS, Let's Encrypt validates it, and the valid wildcard/SAN certificate is installed automatically with zero browser security warnings.

