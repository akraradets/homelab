# Homelab Terraform Infrastructure

This directory contains the Terraform Infrastructure-as-Code (IaC) declarations for the homelab.

---

## 🔒 Security Guidelines (Public Repository)

1. **Credentials**: Never commit `.tfvars`, `*.tfstate`, `.env`, or Service Account `.json` keys.
2. **Template Files**: Only commit `terraform.tfvars.example`.
3. **Local Setup**:
   ```bash
   cp terraform.tfvars.example terraform.tfvars
   # Edit terraform.tfvars with your actual values (this file is ignored by git)
   ```
4. **Remote State**: Use Google Cloud Storage (GCS) to store `.tfstate` files remotely and securely.

---

## Module Layout

- **[`gcp/`](file:///Users/akraradets/Projects/sinsamersuk/homelab/terraform/gcp)**: Google Cloud DNS managed zone and DNS record sets.
- **[`proxmox/`](file:///Users/akraradets/Projects/sinsamersuk/homelab/terraform/proxmox)**: Proxmox VE hypervisor resources, including virtualized TrueNAS SCALE with PCIe controller passthrough and Workstation VMs.
