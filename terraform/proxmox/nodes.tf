# ==============================================================================
# Proxmox VE Discovery Data Sources
# ==============================================================================

# Discover cluster nodes
data "proxmox_virtual_environment_nodes" "available" {}

# Discover PVE version
data "proxmox_virtual_environment_version" "pve_version" {}

# Discover datastores on target node
data "proxmox_virtual_environment_datastores" "datastores" {
  node_name = "pve-1"
}

# Discover existing VMs on target node
data "proxmox_virtual_environment_vms" "existing_vms" {
  node_name = "pve-1"
}

# Discover node hardware specs
data "proxmox_virtual_environment_node" "pve_node" {
  node_name = "pve-1"
}

output "proxmox_version" {
  description = "Proxmox VE release version"
  value       = data.proxmox_virtual_environment_version.pve_version.release
}

output "proxmox_nodes" {
  description = "Active Proxmox VE cluster nodes"
  value       = data.proxmox_virtual_environment_nodes.available.names
}

output "proxmox_datastores" {
  description = "Configured datastores on pve-1"
  value       = data.proxmox_virtual_environment_datastores.datastores.datastore_ids
}

output "proxmox_existing_vms" {
  description = "Existing virtual machines on pve-1"
  value       = [for vm in data.proxmox_virtual_environment_vms.existing_vms.vms : {
    vm_id = vm.vm_id
    name  = vm.name
  }]
}

output "proxmox_hardware" {
  description = "Hardware specifications of the host"
  value = {
    cpu_model        = data.proxmox_virtual_environment_node.pve_node.cpu_model
    cpu_count        = data.proxmox_virtual_environment_node.pve_node.cpu_count
    memory_total_gb  = floor(data.proxmox_virtual_environment_node.pve_node.memory_total / 1073741824)
    memory_avail_gb  = floor(data.proxmox_virtual_environment_node.pve_node.memory_available / 1073741824)
  }
}

data "proxmox_virtual_environment_hardware_mappings" "pci_mappings" {
  type = "pci"
}

output "proxmox_pci_mappings" {
  description = "Existing PCI hardware mappings in Proxmox"
  value       = data.proxmox_virtual_environment_hardware_mappings.pci_mappings.ids
}

