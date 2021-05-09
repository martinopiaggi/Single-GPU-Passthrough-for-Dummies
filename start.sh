#!/bin/bash
# this is for debug, keep it 
set -x

# Stop display manager
systemctl stop display-manager.service


# Unbind VTconsoles
echo 0 > /sys/class/vtconsole/vtcon0/bind
echo 0 > /sys/class/vtconsole/vtcon1/bind

# Unbind EFI-Framebuffer
echo efi-framebuffer.0 > /sys/bus/platform/drivers/efi-framebuffer/unbind

# Avoid a Race condition by waiting 2 seconds.
sleep 2

#Unload Nvidia 
modprobe -r nvidia_drm
modprobe -r nvidia_modeset
modprobe -r drm_kms_helper
modprobe -r nvidia
modprobe -r i2c_nvidia_gpu
modprobe -r drm
modprobe -r nvidia_uvm

# Unbind the GPU from display driver (replace the pci addresses with yours)
virsh nodedev-detach pci_0000_0a_00_0
virsh nodedev-detach pci_0000_0a_00_1

# Load VFIO Kernel Module  
modprobe vfio  
modprobe vfio_pci
modprobe vfio_iommu_type1
