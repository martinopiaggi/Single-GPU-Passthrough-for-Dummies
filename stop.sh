#!/bin/bash
set -x

# Re-Bind GPU to Nvidia Driver (replace the pci addresses with yours)
virsh nodedev-reattach pci_0000_09_00_0
virsh nodedev-reattach pci_0000_09_00_1

modprobe -r vfio-pci

#bind efi
echo "efi-framebuffer.0" > /sys/bus/platform/drivers/efi-framebuffer/bind

# Reload nvidia modules
modprobe nvidia_drm
modprobe nvidia_modeset
modprobe nvidia_uvm
modprobe nvidia

# Rebind VT consoles
echo 1 > /sys/class/vtconsole/vtcon0/bind
echo 1 > /sys/class/vtconsole/vtcon1/bind

# Restart Display Manager
systemctl restart gdm.service

# Bluetooth stuff
#modprobe btusb btrtl hidp btmtk btintel btbcm bnep rfcomm bluetooth
#systemctl enable bluetooth.service
#systemctl start bluetooth.service