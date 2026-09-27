# ==============================================================================
# Ubuntu 24.04 LTS Cloud Image Download
# ==============================================================================
resource "proxmox_virtual_environment_download_file" "ubuntu_cloud_image" {
  node_name           = "pve-1"
  datastore_id        = "truenas-proxmox"
  content_type        = "import"
  overwrite_unmanaged = true

  url       = "https://cloud-images.ubuntu.com/noble/current/noble-server-cloudimg-amd64.img"
  file_name = "noble-server-cloudimg-amd64.qcow2"
}

# ==============================================================================
# Workstation Desktop Virtual Machine (work-desktop) - TEMPORARILY DISABLED
# ==============================================================================
# resource "proxmox_virtual_environment_vm" "work_desktop" {
#   node_name   = "pve-1"
#   vm_id       = 110
#   name        = "work-desktop"
#   description = "Ubuntu 24.04 Desktop Workstation (UID 3000, 100% PVEAPIToken Managed)"
#   tags        = ["workstation", "desktop", "gnome", "xrdp", "terraform"]
# 
#   machine       = "q35"
#   bios          = "ovmf"
#   scsi_hardware = "virtio-scsi-single"
# 
#   started       = true
#   on_boot       = true
#   tablet_device = true
#   boot_order    = ["scsi0"]
# 
#   startup {
#     order    = 2
#     up_delay = 0
#   }
# 
#   agent {
#     enabled = true
#     timeout = "30s"
#   }
# 
#   cpu {
#     cores = 6
#     type  = "host"
#   }
# 
#   memory {
#     dedicated = 16384
#     floating  = 4096
#   }
# 
#   network_device {
#     bridge = "vmbr0"
#     model  = "virtio"
#   }
# 
#   # EFI State Storage
#   efi_disk {
#     datastore_id = "truenas-fast"
#     file_format  = "raw"
#     type         = "4m"
#   }
# 
#   # OS Disk cloned from Ubuntu Cloud Image
#   disk {
#     datastore_id = "truenas-fast"
#     import_from  = proxmox_virtual_environment_download_file.ubuntu_cloud_image.id
#     interface    = "scsi0"
#     file_format  = "raw"
#     iothread     = true
#     discard      = "on"
#     ssd          = true
#   }
# 
#   # Native Proxmox Cloud-Init (100% API Token Managed - Zero Hypervisor SSH)
#   initialization {
#     datastore_id = "truenas-fast"
# 
#     user_account {
#       username = "ubuntu"
#       password = "ubuntu"
#       keys     = ["ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIADpR5J4va1V025W48afmFqO8wNo31QxSHkWA0SBg2t7 akraradets@mbp16"]
#     }
# 
#     ip_config {
#       ipv4 {
#         address = "192.168.55.110/24"
#         gateway = "192.168.55.1"
#       }
#     }
# 
#     dns {
#       domain  = "home.sinsamersuk.net"
#       servers = ["192.168.55.1"]
#     }
#   }
# 
#   # VirtIO-GPU display configuration
#   vga {
#     type   = "virtio"
#     memory = 32
#   }
# 
#   serial_device {}
# }
