# ==============================================================================
# TrueNAS SCALE Virtual Machine with PCIe SATA Controller Passthrough
# ==============================================================================
resource "proxmox_virtual_environment_vm" "truenas_vm" {
  node_name   = "pve-1"
  vm_id       = 100
  name        = "truenas-scale"
  description = "TrueNAS SCALE with Intel Raptor Lake SATA Controller Passthrough (0000:00:17.0)"
  tags        = ["nas", "storage", "truenas", "terraform"]

  # Essential architecture for PCIe Passthrough & TrueNAS
  machine       = "q35"
  bios          = "ovmf"
  scsi_hardware = "virtio-scsi-single"

  operating_system {
    type = "l26"
  }

  started       = true
  on_boot       = true
  tablet_device = false
  boot_order    = ["scsi0", "ide2", "net0"]

  # Agent is disabled during initial install from ISO so Terraform doesn't hang waiting for guest agent
  agent {
    enabled = false
  }

  # VirtIO-GPU with 32MB VRAM fixes garbled/unreadable console text under OVMF (UEFI)
  vga {
    type   = "virtio"
    memory = 32
  }

  cpu {
    cores = 4
    type  = "host"
  }

  memory {
    # 32 GB Dedicated fixed RAM (Ballooning must NOT be used with ZFS and PCIe passthrough)
    dedicated = 32768
  }

  network_device {
    bridge   = "vmbr0"
    model    = "virtio"
    queues   = 4     # Multiqueue: distributes packet queues across all vCPUs for 25-40+ Gbps
    firewall = false # Bypasses netfilter overhead for raw host RAM throughput
  }

  # EFI State Storage
  efi_disk {
    datastore_id = "local-lvm"
    file_format  = "raw"
    type         = "4m"
  }

  # Virtual Boot Drive on fast local-lvm storage (NVMe)
  disk {
    datastore_id = "local-lvm"
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
    file_id   = "local:iso/TrueNAS-26.0.0-BETA.3.iso"
    interface = "ide2"
  }

  # Direct PCIe Passthrough via Proxmox Resource Mapping
  hostpci {
    device  = "hostpci0"
    mapping = proxmox_virtual_environment_hardware_mapping_pci.sata_controller.name
    pcie    = true
    rombar  = true
  }

  lifecycle {
    ignore_changes = [
      cdrom, # Prevents Terraform from reattaching the installer ISO after initial OS install
    ]
  }
}
