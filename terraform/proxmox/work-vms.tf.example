# ==============================================================================
# Workstation Desktop VM (SPICE Display + qemu-vdagent support)
# ==============================================================================
resource "proxmox_virtual_environment_vm" "work_desktop" {
  node_name   = var.pve_node_name
  vm_id       = var.work_desktop_vm_id
  name        = "work-desktop"
  description = "Managed by Terraform - Desktop Workstation VM"
  tags        = ["workstation", "desktop", "spice", "terraform"]

  machine       = "q35"
  bios          = "ovmf"
  scsi_hardware = "virtio-scsi-single"

  started       = true
  on_boot       = false
  tablet_device = false

  agent {
    enabled = true
  }

  cpu {
    cores = var.work_desktop_cores
    type  = "host"
  }

  memory {
    dedicated = var.work_desktop_memory_mb
    floating  = 4096 # Allow ballooning between 4GB and dedicated RAM
  }

  network_device {
    bridge = var.network_bridge
    model  = "virtio"
  }

  # EFI State Storage
  efi_disk {
    datastore_id = var.datastore_id
    file_format  = "raw"
    type         = "4m"
  }

  # OS Disk
  disk {
    datastore_id = var.datastore_id
    interface    = "scsi0"
    size         = 64
    file_format  = "raw"
    iothread     = true
    discard      = "on"
    ssd          = true
  }

  # SPICE Display Configuration for fluid cursor, resolution autoscaling, and clipboard
  vga {
    type   = "qxl"
    memory = 32
  }
}
