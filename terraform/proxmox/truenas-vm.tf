# ==============================================================================
# TrueNAS SCALE Virtual Machine with PCIe SATA Controller Passthrough
# ==============================================================================
resource "proxmox_virtual_environment_vm" "truenas_vm" {
  node_name   = var.pve_node_name
  vm_id       = var.truenas_vm_id
  name        = "truenas-scale"
  description = "Managed by Terraform - TrueNAS SCALE with PCIe SATA Passthrough"
  tags        = ["nas", "storage", "truenas", "terraform"]

  # Essential architecture for PCIe Passthrough & TrueNAS
  machine       = "q35"
  bios          = "ovmf"
  scsi_hardware = "virtio-scsi-single"

  started       = true
  on_boot       = true
  tablet_device = false

  agent {
    enabled = true
  }

  cpu {
    cores = var.truenas_cores
    type  = "host"
  }

  memory {
    # Fixed allocation: Ballooning must NOT be used with ZFS and PCIe passthrough
    dedicated = var.truenas_memory_mb
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

  # Virtual Boot Drive on fast local storage (NVMe/SSD)
  disk {
    datastore_id = var.datastore_id
    interface    = "scsi0"
    size         = 32
    file_format  = "raw"
    iothread     = true
    discard      = "on"
    ssd          = true
  }

  # TrueNAS SCALE Installer ISO
  cdrom {
    enabled   = true
    file_id   = var.truenas_iso_file_id
    interface = "ide2"
  }

  # Direct PCIe Passthrough of Motherboard SATA Controller or SAS HBA
  hostpci {
    device = "hostpci0"
    id     = var.sata_controller_pci_id
    pcie   = true
    rombar = true
  }

  lifecycle {
    ignore_changes = [
      cdrom, # Prevents Terraform from reattaching the installer ISO after initial OS install
    ]
  }
}
