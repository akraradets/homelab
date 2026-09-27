# AI Agent Guidelines & Context

This file serves as persistent memory and instructions for AI agents (including Antigravity) working in this repository.

---

## 1. Project Overview & Role

This repository serves two primary functions:
1. **Homelab Knowledge Base**: Personal documentation and runbooks viewed, searched, and edited in **Obsidian**.
2. **Infrastructure as Code (IaC)**: Declarative management of home infrastructure using **Terraform**.

---

## 2. Core Homelab Architecture

- **Single Physical Host**: Bare-metal **Proxmox VE** hypervisor with IOMMU / VFIO enabled.
- **Virtualized Storage Appliance**: **TrueNAS SCALE** running as VM (`vm_id = 100`):
  - Motherboard SATA / SAS HBA storage controller passed directly to TrueNAS via PCIe passthrough (`hostpci`).
  - Virtual 32 GB boot disk on NVMe (`local-lvm`).
  - TrueNAS runs ZFS directly against physical drives for native SMART health and scrub integrity.
  - Serves SMB shares and **Apple Time Machine** (with strict dataset quotas).
- **Compute Workloads**:
  - Desktop Workstation VM (SPICE display + `qemu-vdagent` for resolution auto-resizing and clipboard).
  - Headless Development VMs for containers and background jobs.
  - Mounts TrueNAS storage over the virtual Linux bridge (`vmbr0`) at **near-memory speeds (~15–25+ Gbps)** in host RAM.
- **Remote Access (Zero Inbound Ports)**:
  - **NetBird Cloud** (managed free tier at `app.netbird.io`).
  - Proxmox host (or a dedicated LXC) functions as a **Routing Peer / Subnet Router** forwarding `192.168.55.0/24`.
  - WireGuard P2P direct encryption; zero open ports required on the home router.
- **Google Cloud Platform (Project `sinsamersuk`)**:
  - **Cloud DNS**: Authoritative public managed zone `sinsamersuk-net` (`sinsamersuk.net.`).
  - **Cloud Storage (GCS)**: Bucket `sinsamersuk-homelab-tfstate` holds remote Terraform state files.
  - **Secret Manager**: Secret `pve-api-token` holds the Proxmox API token (`root@pam!terraform=UUID`).
  - **Service Accounts**:
    - `terraform-admin@sinsamersuk.iam.gserviceaccount.com` (key at `terraform/gcp/credentials.json`) for IaC automation.
    - `pve-acme@sinsamersuk.iam.gserviceaccount.com` (key at `terraform/gcp/pve-acme-sa.json`) with `roles/dns.admin` for Proxmox ACME DNS-01 challenges.
- **Terraform Execution & Credential Pattern**:
  - Run `./scripts/bootstrap.sh` to populate git-ignored local credential files from GCP:
    - `terraform/gcp/credentials.json` (Service account key)
    - `terraform/proxmox/terraform.tfvars` (Proxmox API token from Secret Manager)
  - Run standard `terraform plan` and `terraform apply` in each directory with zero inline secret flags.
  - NEVER commit `terraform.tfvars` or `credentials.json` (strictly git-ignored).

---

## 3. Security & Public Repository Rules (CRITICAL)

This repository is **publicly accessible**. The agent must strictly follow these rules:

1. **Zero Secret Leakage**:
   - Never commit `*.tfstate`, `*.tfvars`, `.env*`, private keys (`*.key`, `*.pem`), or Service Account keys (`*credentials*.json`, `*sa*.json`).
   - All secrets must be git-ignored via `.gitignore`.
2. **Zero Home IP Leakage**:
   - Residential public IP addresses (e.g. `58.136.x.x`) must never be written to tracked markdown or `.tf` files.
   - Use RFC-compliant dummy values (`example.com`, `192.168.1.0/24`, `203.0.113.1`) for documentation and examples.
3. **Multi-Account Credential Isolation**:
   - Always configure the Google provider with local `credentials.json` so Terraform operations never collide with global `gcloud` user accounts.
4. **GCP Secret Manager Free Tier Budget Guardrail (Max 6 Active Versions)**:
   - Secret Manager provides **up to 6 active secret versions 100% free** per month.
   - The total active secret versions in project `sinsamersuk` must **never exceed 6**.
   - Current Inventory:
     - `pve-api-token` (Proxmox VE API Token) — 1 active version.
   - When rotating secret values, **always destroy deprecated versions** via `gcloud secrets versions destroy <OLD_VERSION> --secret=<SECRET>` so inactive versions do not consume the 6-version free tier quota.

---

## 4. Obsidian Documentation Conventions

All documentation files reside in [`docs/`](./docs/):
- **Entry Hub / MOC**: [`docs/00-index.md`](./docs/00-index.md) links to all topics.
- **Wikilinks**: Use native Obsidian wikilinks: `[[category/filename|Display Name]]`.
- **Mermaid Diagrams**: Use native Mermaid fences (````mermaid ... ````) for architecture topologies.
- **Callouts**: Use Obsidian callouts (`> [!NOTE]`, `> [!TIP]`, `> [!WARNING]`).

---

## 5. Terraform Directory Conventions

- **[`terraform/gcp/`](./terraform/gcp/)**:
  - `main.tf`: Provider setup and GCS backend.
  - `dns.tf`: Declarative Cloud DNS zone and records in pure HCL.
  - `outputs.tf`: Zone and nameserver outputs.
- **[`terraform/proxmox/`](./terraform/proxmox/)**:
  - Uses `bpg/proxmox` provider.
  - `truenas-vm.tf`: TrueNAS SCALE VM with PCIe controller passthrough.
  - `work-vms.tf`: Workstation VM definitions.
