# ==============================================================================
# Proxmox VE Hardware Resource Mapping (PCI Passthrough)
# ==============================================================================

resource "proxmox_virtual_environment_hardware_mapping_pci" "sata_controller" {
  name    = "sata-controller"
  comment = "Intel Raptor Lake SATA AHCI Controller for TrueNAS"

  map = [
    {
      node         = "pve-1"
      path         = "0000:00:17.0"
      id           = "8086:7a62"
      subsystem_id = "1043:8882"
      iommu_group  = 9
    }
  ]
}

resource "proxmox_virtual_environment_hardware_mapping_pci" "nvme_fast_storage" {
  name    = "nvme-fast-storage"
  comment = "PNY CS3030 2TB NVMe SSD for TrueNAS VM Storage"

  map = [
    {
      node         = "pve-1"
      path         = "0000:03:00.0"
      id           = "1987:5012"
      subsystem_id = "1987:5012"
      iommu_group  = 17
    }
  ]
}

resource "proxmox_virtual_environment_hardware_mapping_pci" "intel_uhd" {
  name    = "intel-uhd"
  comment = "Intel Alder Lake-S GT1 [UHD Graphics 770]"

  map = [
    {
      node         = "pve-1"
      path         = "0000:00:02.0"
      id           = "8086:4680"
      subsystem_id = "1043:8882"
      iommu_group  = 0
    }
  ]
}
