# ==============================================================================
# Workstation Desktop Virtual Machine (work-desktop)
# Ubuntu Desktop with Intel UHD 770 Passthrough & Sunshine/Moonlight Streaming
# ==============================================================================
resource "proxmox_virtual_environment_vm" "work_desktop" {
  node_name   = "pve-1"
  vm_id       = 110
  name        = "work-desktop"
  description = "Ubuntu 26.04 Desktop Workstation (Intel UHD 770 Passthrough, UID 3000)"
  tags        = ["workstation", "desktop", "intel-uhd", "moonlight", "terraform"]

  machine       = "q35"
  bios          = "ovmf"
  scsi_hardware = "virtio-scsi-single"

  operating_system {
    type = "l26"
  }

  started       = true
  on_boot       = true
  tablet_device = true
  boot_order    = ["ide3", "scsi0"]

  startup {
    order    = 2
    up_delay = 0
  }

  agent {
    enabled = true
    timeout = "30s"
  }

  cpu {
    cores = 6
    type  = "host"
  }

  memory {
    dedicated = 16384
    floating  = 4096
  }

  network_device {
    bridge   = "vmbr0"
    model    = "virtio"
    firewall = false
  }

  # EFI State Storage
  efi_disk {
    datastore_id = "truenas-fast"
    file_format  = "raw"
    type         = "4m"
  }

  # Primary OS Virtual Disk on Fast NVMe Pool
  disk {
    datastore_id = "truenas-fast"
    interface    = "scsi0"
    file_format  = "raw"
    size         = 64
    iothread     = true
    discard      = "on"
    ssd          = true
  }

  # Ubuntu Desktop ISO (CD-ROM)
  cdrom {
    enabled   = true
    file_id   = "truenas-proxmox:iso/ubuntu-26.04.1-desktop-amd64.iso"
    interface = "ide3"
  }

  # Virtual Display for Proxmox Web noVNC Console
  vga {
    type   = "virtio"
    memory = 32
  }

  # Intel UHD Graphics 770 Hardware Passthrough (Quick Sync Video)
  hostpci {
    device  = "hostpci0"
    mapping = proxmox_virtual_environment_hardware_mapping_pci.intel_uhd.name
    pcie    = true
    rombar  = false
    xvga    = false
  }

  serial_device {}
}
