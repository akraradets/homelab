# ==============================================================================
# Workstation Desktop Virtual Machine (work-desktop)
# Ubuntu Desktop with NVIDIA GeForce RTX 3060 12GB Passthrough & Sunshine
# ==============================================================================
resource "proxmox_virtual_environment_vm" "work_desktop" {
  node_name   = "pve-1"
  vm_id       = 110
  name        = "work-desktop"
  description = "Ubuntu 26.04 Desktop Workstation (NVIDIA RTX 3060 12GB Passthrough, UID 3000)"
  tags        = ["workstation", "desktop", "nvidia-rtx3060", "sunshine", "terraform"]

  machine       = "q35"
  bios          = "ovmf"
  scsi_hardware = "virtio-scsi-single"

  operating_system {
    type = "l26"
  }

  started       = true
  on_boot       = true
  tablet_device = true
  boot_order    = ["scsi0"]

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

  # Headless Display (Pure NVIDIA GPU Output, Zero Emulated Displays)
  vga {
    type = "none"
  }

  # NVIDIA GeForce RTX 3060 12GB PCIe Hardware Passthrough
  hostpci {
    device  = "hostpci0"
    mapping = proxmox_virtual_environment_hardware_mapping_pci.nvidia_rtx3060.name
    pcie    = true
    rombar  = false
    xvga    = true
  }

  serial_device {}
}
