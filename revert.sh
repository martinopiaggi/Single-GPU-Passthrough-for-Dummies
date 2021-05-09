#!/bin/bash
#this is for debug, keep it
set -x

#unload vfio-pci
modprobe -r vfio_pci
modprobe -r vfio_iommu_type1
modprobe -r vfio
  
# Re-Bind GPU to Nvidia Driver (replace the pci addresses with yours)
virsh nodedev-reattach pci_0000_0a_00_0
virsh nodedev-reattach pci_0000_0a_00_1

# Rebind VT consoles
echo 1 > /sys/class/vtconsole/vtcon0/bind
echo 1 > /sys/class/vtconsole/vtcon1/bind

#read nvidia-xconfig
nvidia-xconfig --query-gpu-info > /dev/null 2>&1

#bind efi
echo "efi-framebuffer.0" > /sys/bus/platform/drivers/efi-framebuffer/bind

#load nvidia
modprobe nvidia_drm
modprobe nvidia_modeset
modprobe drm_kms_helper
modprobe nvidia
modprobe drm
modprobe nvidia_uvm

# Restart Display Manager
systemctl start display-manager.service
