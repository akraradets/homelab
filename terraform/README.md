# Homelab Terraform Infrastructure

This directory contains declarative Infrastructure-as-Code (IaC) declarations for Google Cloud Platform and Proxmox VE.

---

## 🔒 Cloud-Native Secret Management (Zero Local `.tfvars`)

This repository is publicly accessible. Rather than storing sensitive credentials in local `terraform.tfvars` files on disk, all sensitive tokens are stored encrypted in **Google Cloud Secret Manager** and injected into memory at run-time:

- **GCP Secrets**:
  - `pve-api-token`: Proxmox VE API Token (`root@pam!terraform=UUID`), managed via [`gcp/secret-manager.tf`](./gcp/secret-manager.tf).
- **GCS Remote State**:
  - Encrypted backend bucket: `gs://sinsamersuk-homelab-tfstate/`
  - Separate state prefixes: `terraform/state/gcp` and `terraform/state/proxmox`.

---

## Execution Runbook

### 1. Managing GCP Resources (`terraform/gcp`)
The Google provider uses the isolated Service Account key at `terraform/gcp/credentials.json` (git-ignored):
```bash
cd terraform/gcp
terraform init
terraform plan
terraform apply
```

### 2. Managing Proxmox Resources (`terraform/proxmox`)
The Proxmox provider reads `proxmox_api_token` dynamically from Google Cloud Secret Manager:

#### Running in Terminal:
```bash
cd terraform/proxmox

# Fetch token into environment variable in RAM
export TF_VAR_proxmox_api_token=$(gcloud secrets versions access latest --secret=pve-api-token --project=sinsamersuk)

terraform plan
terraform apply
```

#### Or as a single inline command:
```bash
cd terraform/proxmox
terraform plan -var="proxmox_api_token=$(gcloud secrets versions access latest --secret=pve-api-token --project=sinsamersuk)"
```

---

## Module Layout

- **[`gcp/`](./gcp)**: Google Cloud DNS zone (`sinsamersuk.net.`), ACME service accounts, and Secret Manager containers.
- **[`proxmox/`](./proxmox)**: Proxmox VE hypervisor resources:
  - `main.tf`: Provider setup and GCS backend.
  - `nodes.tf`: Dynamic cluster discovery (nodes, datastores, hardware specs).
  - `hardware.tf`: PCI hardware resource mappings (`sata-controller` for PCIe passthrough).
  - `truenas-vm.tf`: TrueNAS SCALE VM with 32 GB RAM and SATA controller passthrough.
  - `outputs.tf`: VM IDs and resource metadata.
