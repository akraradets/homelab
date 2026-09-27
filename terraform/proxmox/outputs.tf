output "truenas_vm_id" {
  description = "The VM ID of the TrueNAS SCALE virtual machine."
  value       = proxmox_virtual_environment_vm.truenas_vm.vm_id
}

output "truenas_vm_name" {
  description = "The name of the TrueNAS SCALE virtual machine."
  value       = proxmox_virtual_environment_vm.truenas_vm.name
}

# output "work_desktop_vm_id" {
#   description = "The VM ID of the Ubuntu Workstation Desktop."
#   value       = proxmox_virtual_environment_vm.work_desktop.vm_id
# }
# 
# output "work_desktop_ip" {
#   description = "Static IP address of the Workstation Desktop."
#   value       = "192.168.55.110"
# }
# 
# output "work_desktop_rdp" {
#   description = "RDP connection endpoint for Microsoft Remote Desktop."
#   value       = "192.168.55.110:3389"
# }
