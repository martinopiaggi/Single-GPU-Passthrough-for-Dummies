#!/bin/bash
# this is for debug, keep it
set -x

# Stop display manager
systemctl stop gdm.service

# Unbind VTconsoles
echo 0 > /sys/class/vtconsole/vtcon0/bind
echo 0 > /sys/class/vtconsole/vtcon1/bind

# Unbind EFI-Framebuffer
echo efi-framebuffer.0 > /sys/bus/platform/drivers/efi-framebuffer/unbind

modprobe -r nvidia_drm nvidia_modeset nvidia_uvm nvidia

# Unbind the GPU from display driver (replace the pci addresses with yours)
virsh nodedev-detach pci_0000_09_00_0
virsh nodedev-detach pci_0000_09_00_1

# Load VFIO Kernel Module 
modprobe vfio_pci


#bluetooth stuff
#systemctl disable bluetooth.service
#systemctl stop bluetooth.service
#modprobe -r btusb btrtl hidp btmtk btintel btbcm bnep rfcomm bluetooth
#sleep 0.5 
#modprobe -r btusb btrtl hidp btmtk btintel btbcm bnep rfcomm bluetooth