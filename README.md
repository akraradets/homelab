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
    │   ├── secret-manager.tf
    │   └── outputs.tf
    └── proxmox/                   # Proxmox VE hypervisor resources
        ├── main.tf                # Provider setup & GCS backend
        ├── nodes.tf               # Cluster discovery (nodes, datastores, specs)
        ├── hardware.tf            # PCI device mappings (SATA controller passthrough)
        ├── truenas-vm.tf          # TrueNAS SCALE VM definition (32 GB RAM)
        └── outputs.tf
```

---

## Getting Started

This repository uses a **Stateless Infrastructure Pattern**. No credentials or `.tfvars` files are tied to your local computer. Your Google Cloud identity is the single root of trust.

### Prerequisites
- [Google Cloud SDK (`gcloud`)](https://cloud.google.com/sdk/docs/install)
- [Terraform](https://developer.hashicorp.com/terraform/install) (>= 1.5.0)
- [Obsidian](https://obsidian.md) (for viewing architecture runbooks)

---

### Step 1: Clone & Authenticate with Google Cloud
From any machine (Mac, Linux, or Cloud Workstation):

```bash
git clone https://github.com/akraradets/homelab.git
cd homelab

# Authenticate with Google Cloud (project sinsamersuk)
gcloud auth login
gcloud config set project sinsamersuk
```

---

### Step 2: Bootstrap Local Credentials
Run the bootstrap script once. It automatically creates the git-ignored GCP Service Account key and fetches the Proxmox API token from **GCP Secret Manager** into a local `terraform.tfvars`:

```bash
./scripts/bootstrap.sh
```

---

### Step 3: Manage Cloud Infrastructure (`terraform/gcp`)
Manages Google Cloud DNS (`sinsamersuk.net.`), Let's Encrypt ACME credentials, and Secret Manager containers with encrypted remote state in GCS:

```bash
cd terraform/gcp
terraform init
terraform plan
terraform apply
```

---

### Step 4: Manage Proxmox & TrueNAS (`terraform/proxmox`)
With `terraform.tfvars` automatically populated by the bootstrap script, run standard Terraform commands with zero manual secrets or inline flags:

```bash
cd terraform/proxmox
terraform init
terraform plan
terraform apply
```

> [!NOTE]
> **GCP Secret Manager Free Tier Policy (Max 6 Active Versions)**:
> Google Cloud provides **up to 6 active secret versions** and **10,000 access operations/month** 100% free. This repository strictly caps active secrets to $\le 6$ (current inventory: `pve-api-token`, 1 active version). When rotating secrets, always destroy deprecated versions (`gcloud secrets versions destroy <OLD_VERSION> --secret=<NAME>`) to remain permanently within the Free Tier.

---

### 5. Knowledge Base & Runbooks (Obsidian)
Open this repository folder directly in [Obsidian](https://obsidian.md).
- Entry navigation hub: [`docs/00-index.md`](./docs/00-index.md)
- Complete topology & ACME guide: [`docs/architecture.md`](./docs/architecture.md)
- Terraform security & details: [`terraform/README.md`](./terraform/README.md)

