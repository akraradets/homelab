# Homelab Infrastructure & Documentation

This repository serves as the single source of truth for my homelab architecture documentation and Infrastructure-as-Code (IaC) using Terraform.

> [!NOTE]
> **Public Repository Policy**: This repository is publicly accessible. All domain names, IP addresses, credentials, and sensitive identifiers are sanitized using RFC-compliant placeholders (`example.com`, `192.168.1.0/24`). Real credentials and `.tfstate` files are strictly excluded via `.gitignore` and managed through private Google Cloud Storage (GCS) backends.

---

## Architecture Summary

- **Hypervisor**: Single physical host running **Proxmox VE** bare-metal with IOMMU enabled.
- **Storage Appliance**: **TrueNAS SCALE** virtualized inside Proxmox (VM ID `100`):
  - Dedicated PCIe passthrough of the physical SATA / SAS HBA storage controller directly to the TrueNAS VM for native ZFS health & SMART control.
  - Virtual 32 GB boot drive on NVMe SSD (`local-lvm`).
- **Compute Workloads**:
  - Workstation Desktop VM (SPICE display driver + `qemu-vdagent` for smooth cursor, clipboard, and resolution scaling).
  - Headless Development VMs for containers and background workloads.
- **High-Speed Interconnect**:
  - Communication between compute VMs and TrueNAS storage runs over the internal Linux bridge (`vmbr0`) at **near-memory speeds (~15–25+ Gbps)** in host RAM, eliminating the need for 10GbE network cards.
- **External Networking & DNS**:
  - Authoritative DNS managed via **Google Cloud DNS** (`terraform/gcp`).
  - Remote state managed securely in an encrypted **Google Cloud Storage (GCS)** bucket.
  - Apple Time Machine backups hosted over SMB with enforced dataset quotas.

---

## Repository Structure

```text
.
├── .obsidian/                     # Obsidian vault configuration (Obsidian Git auto-backup)
├── .gitignore                     # Hardened against secrets, .tfvars, and *.tfstate
├── AGENTS.md                      # AI agent memory and architecture constraints
├── README.md                      # High-level architecture & repo overview
│
├── docs/                          # Homelab Documentation (Obsidian Markdown)
│   ├── 00-index.md                # Vault navigation & index
│   └── architecture.md            # Complete architecture, networking, DNS, and ACME runbook
│
└── terraform/                     # Infrastructure-as-Code
    ├── README.md                  # Terraform usage instructions & security guide
    ├── gcp/                       # Google Cloud DNS zone, records, & ACME IAM
    │   ├── main.tf
    │   ├── dns.tf
    │   ├── iam.tf
    │   └── outputs.tf
    └── proxmox/                   # Proxmox VE hypervisor resources
        ├── main.tf
        ├── truenas-vm.tf          # TrueNAS SCALE VM with PCIe SATA passthrough
        ├── work-vms.tf            # Workstation VM definitions
        ├── variables.tf
        ├── outputs.tf
        ├── versions.tf
        └── terraform.tfvars.example
```

---

## Getting Started

### 1. Homelab Notes (Obsidian)
Open this repository folder directly in [Obsidian](https://obsidian.md). The notes are cross-linked using Obsidian wikilinks `[[...]]` with full Mermaid diagram support. Start at [`docs/00-index.md`](file:///Users/akraradets/Projects/sinsamersuk/homelab/docs/00-index.md) or [`docs/architecture.md`](file:///Users/akraradets/Projects/sinsamersuk/homelab/docs/architecture.md).

### 2. Terraform Infrastructure
See [`terraform/README.md`](file:///Users/akraradets/Projects/sinsamersuk/homelab/terraform/README.md) and [`docs/architecture.md`](file:///Users/akraradets/Projects/sinsamersuk/homelab/docs/architecture.md) for step-by-step instructions on setting up local untracked credentials and running `terraform plan` / `terraform apply`.

