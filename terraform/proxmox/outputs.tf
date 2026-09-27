output "truenas_vm_id" {
  description = "The VM ID of the TrueNAS SCALE virtual machine."
  value       = proxmox_virtual_environment_vm.truenas_vm.vm_id
}

output "truenas_vm_name" {
  description = "The name of the TrueNAS SCALE virtual machine."
  value       = proxmox_virtual_environment_vm.truenas_vm.name
}
