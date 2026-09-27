variable "proxmox_endpoint" {
  type        = string
  description = "The Proxmox VE API endpoint URL."
  default     = "https://pve-1.home.sinsamersuk.net:8006/"
}

variable "proxmox_insecure" {
  type        = bool
  description = "Whether to skip TLS certificate verification."
  default     = false
}

variable "proxmox_api_token" {
  type        = string
  description = "The Proxmox API token (e.g. USER@REALM!TOKENID=UUID). Recommended over password."
  default     = null
  sensitive   = true
}

variable "proxmox_username" {
  type        = string
  description = "Proxmox username (e.g. root@pam) if not using API token."
  default     = null
}

variable "proxmox_password" {
  type        = string
  description = "Proxmox password if not using API token."
  default     = null
  sensitive   = true
}

variable "pve_node_name" {
  type        = string
  description = "The target Proxmox VE node name."
  default     = "pve-1"
}

variable "network_bridge" {
  type        = string
  description = "The Proxmox network bridge for internal VM interconnect."
  default     = "vmbr0"
}

variable "datastore_id" {
  type        = string
  description = "Proxmox storage pool for virtual disks and EFI states (e.g. local-lvm or local-zfs)."
  default     = "local-lvm"
}

# ------------------------------------------------------------------------------
# TrueNAS SCALE VM Variables
# ------------------------------------------------------------------------------
variable "truenas_vm_id" {
  type        = number
  description = "Proxmox VM ID for TrueNAS SCALE."
  default     = 100
}

variable "truenas_memory_mb" {
  type        = number
  description = "Dedicated RAM in MB for TrueNAS SCALE (fixed, no ballooning)."
  default     = 32768
}

variable "truenas_cores" {
  type        = number
  description = "Number of CPU cores for TrueNAS SCALE."
  default     = 4
}

variable "truenas_iso_file_id" {
  type        = string
  description = "File ID of the TrueNAS installer ISO in Proxmox."
  default     = "local:iso/TrueNAS-26.0.0-BETA.3.iso"
}

variable "sata_controller_pci_id" {
  type        = string
  description = "The PCI ID of the SATA or SAS HBA controller to pass through to TrueNAS."
  default     = "0000:00:17.0"
}

# ------------------------------------------------------------------------------
# Workstation VM Variables
# ------------------------------------------------------------------------------
variable "work_desktop_vm_id" {
  type        = number
  description = "Proxmox VM ID for Desktop Workstation VM."
  default     = 110
}

variable "work_desktop_memory_mb" {
  type        = number
  description = "RAM in MB for Desktop Workstation VM."
  default     = 8192
}

variable "work_desktop_cores" {
  type        = number
  description = "Number of CPU cores for Desktop Workstation VM."
  default     = 4
}
