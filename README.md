# Single GPU Passthrough for Dummies


## **Table Of Contents**
* **[Introduction](#introduction)**
* **[Initials steps](#initials-steps)**
* **[Patched VBIOS](#patched-vbios)**
* **[Passthrough time](#passthrough-time)**
* **[Hooks](#hooks)**
* **[Benchmarks](#benchmarks)**
* **[Troubleshooting and Resources](#troubleshooting-and-resources)**

## Introduction 

This guide combines many other single GPU guides into a solution for achieving VFIO/IOMMU GPU passthrough without the need to purchase a second GPU or in the case of a Mini-ITX build with no iGPU (like mine). I will only consider Nvidia GPUs, the process with AMD GPUs should be similar. 

Successfully tested on:

- mobo: Asus Strix X570-I (itx)
- cpu: Ryzen 3900x
- gpu: gtx 1070ti Msi Armor 
- host os: Ubuntu 22.10 / Manjaro 
- guest os: Windows 11 / Windows 10  


## Initials steps

In my opinion (and not only mine), the most comprehensive resource available for this topic is the [Wiki Arch](https://wiki.archlinux.org/title/PCI_passthrough_via_OVMF) guide. This guide is like a bible for this topic and it's applicable **not only** for Arch users, but it is still useable also (for example) on Ubuntu. 

To speed run the guide you can follow the next steps:

0) Ensure that AMD-Vi/Intel VT-d is supported by the CPU and enabled in the BIOS settings. Also enable IOMMU:
    - Intel cpu: ``sudo kernelstub --add-options "intel_iommu=on"``
    - AMD cpu: ``sudo kernelstub --add-options "amd_iommu=on"``

    After reboot your system, `dmesg | grep IOMMU` command output should include the message `Intel-IOMMU: enabled` or `AMD-Vi: AMD IOMMUv2 loaded and initialized`. 
[You just did steps 2.1 and 2.2 of arch guide](https://wiki.archlinux.org/title/PCI_passthrough_via_OVMF#Enabling_IOMMU).

1) Install necessary tools depending on your distro: 
    - Ubuntu: ``apt install qemu-kvm qemu-utils libvirt-daemon-system libvirt-clients bridge-utils virt-manager ovmf``
    - Arch Linux: ```pacman -S qemu libvirt edk2-ovmf virt-manager dnsmasq ebtables```

2) Enable required services ```enable systemctl enable --now libvirtd```

3) You should add your user to libvirt group (many times it's automatically done)     
  ```usermod -aG kvm,input,libvirt <username>```

4) All the previous steps are basically the stuff wrote [here](https://wiki.archlinux.org/title/PCI_passthrough_via_OVMF#Setting_up_an_OVMF-based_guest_VM) (yes we have jumped from chapter 2.2 of the guide and to chapter 4 in the guide but trust me, I'm an engineer). Using virt-manager (GUI) is easy (even for dummies like us) setting up the VM (this is represented by [the chapter 4.2 of the Arch guide](https://wiki.archlinux.org/title/PCI_passthrough_via_OVMF#Setting_up_the_guest_OS). If you want to run Windows 11 as guest, the most important steps are: 

    - In Overview section, set Chipset to Q35, and Firmware to UEFI (to do this, you have to Select Customize before install on Final Step)
    - Remember to add TPM 2.0 or use a guide to skip TPM check directly during Windows installation ([like this](https://www.tomshardware.com/how-to/bypass-windows-11-tpm-requirement)).


Ok, you should arrive in this step with a working guest VM **without** any GPU passed.

## Patched VBIOS

Most of GPUs have to be patched for passthrought. To do this you'll need two things: 

1) a rom file called "VBIOS" of your GPU. You can find the VBIOS for your GPU on [TechPowerUp](https://www.techpowerup.com/vgabios/) .  
2) modify this file by using an Hex Editor, (for example one is called Bless). You have to search by "text value" (not hex number) and find the first instance of `VIDEO` using the finder tool and delete all characters before the character `U` that immediately precedes it. (or alternatevely (but it's the same) search string (always in TEXT value) `VIDEO`, and remove everything before hex value 55). This will create a patched VBIOS file that should start with `U...K7400.L.w.VIDEO`. If it starts with a similar sequence, you have patched it. 

## Passthrough time

Using the virt-manager GUI, remove Channel Spice, Display Spice, Video QXL. It's well written [in the chapter 4.3](https://wiki.archlinux.org/title/PCI_passthrough_via_OVMF#Attaching_the_PCI_devices).

Now it's time for the .rom file of your GPU firmware. After adding all the PCI devices related to your GPU and after enabling the XML editing in virt-manager (open virt-manager>edit>preferences>general>enable xml editing) you have to edit the XML of your PCI devices. 

```XML
...
<hostdev mode='subsystem' type='pci' managed='yes'>
  <source>
    ...
  </source>
  <rom file='/path/patched.rom'/>
  ...
</hostdev>
...
```

I strongly suggest (trick found in [this troubleshooting guide](https://docs.google.com/document/d/17Wh9_5HPqAx8HHk-p2bGlR0E-65TplkG18jvM98I7V8/edit#)) to put the rom here: `/usr/share/vgabios/` (make the directory if it doesn’t exist). 

## Hooks

Now it's time for the "hooks" that make the magic to attach and detach the gpu . 
You have to replicate this structure into your `/etc/libvirt/` folder (make a folder called hooks) and inside this folder, make this structure of folders:

```
├── qemu
└── qemu.d
    └── <name of your VM> 
        ├── prepare
        │   └── begin
        │       └── start.sh
        └── release
            └── end
                └── stop.sh
```

In this repo, you'll find the `qemu`, `start.sh`, and `stop.sh` files. `qemu.d` is a folder (yeah, it's a guide for dummies). These files aren't created by me and are designed for **Nvidia** cards like mine. Anything in the begin directory will start when you launch your VM, while anything in the end directory will run when you stop the VM. You could take advantage of these scripts also to automatically schedule events: such as changing the fan speed or case LEDs based on which VM you have launched. For example, you can also enable/disable services that you do or do not want to run while using the VM adding lines in these scripts.

## Benchmarks 

### CPU Benchmark

CPU benchmark with Cinebench R23 (points, higher is better, average of 3 runs):

| Native (points) | in KVM (points) | 
|:---:|:--:|
| 13625  | 12259 | 

### GPU Benchmark

GPU benchmark with Superposition benchmark 2017, just one run.

#### Native

![NATIVE](https://user-images.githubusercontent.com/72280379/225963717-096d4b89-f33b-4879-8aa7-625dc789a5a3.png)

#### Passthrough 

![KVM](https://user-images.githubusercontent.com/72280379/225963744-0f9be01e-691a-4b72-93a2-31ac1e7ea4a1.png)

*note that RAM and OS are recognized incorrectly, they are the same of native test* 

## Troubleshooting and Resources 

- a bug that hit me was to have black screen of the KVM at shutdown of the guest with any errors or clue to solve it. Simply black. I found that `start+x >> Device Manager >> Display Adapters >> Right click on GPU >> disable device` procedure before shutting down the guest (it can be automatized with a script using [PnPUtil](https://learn.microsoft.com/en-us/windows-hardware/drivers/devtest/pnputil-examples)) solve the bug.

- [super useless guide to troubleshoot](https://docs.google.com/document/d/17Wh9_5HPqAx8HHk-p2bGlR0E-65TplkG18jvM98I7V8/edit#)

- [more serious guide](https://github.com/QaidVoid/Complete-Single-GPU-Passthrough/blob/master/README.md)

- [more serious guide 2 (but not single passthrough)](https://github.com/bryansteiner/gpu-passthrough-tutorial)

- if you want to pass bluetooth, the best option is to pass the PCI associated with the bluetooth device. To pass PCI devices that are not GPUs is super simple, just attach it without any tweak using virt-manager. I notice that if I don't pass the PCI device but Bluetooth device as USB I get error code 10 in win11. In my case a way to fix the error 10 (without the PCI detach) is [stopping bluetooth services and removing the modules of bluetooth](https://www.reddit.com/r/VFIO/comments/nej8me/comment/i4xqnvq/) using modprobe.

- More info about `qemu` and hooks are [here](https://passthroughpo.st/simple-per-vm-libvirt-hooks-with-the-vfio-tools-hook-helper/ ) and [here](https://github.com/PassthroughPOST/VFIO-Tools/tree/master/libvirt_hooks).

- You can integrate this guide with the the [funniest tutorial ever about this topic](https://www.youtube.com/watch?v=BUSrdUoedTo). The video is very usefull and complete but there are little imperfections: in the ```revert.sh``` (we have named the file ```stop.sh```) Muta (the youtuber) has accidentally wrote echo 1 instead of echo 0. Remember that Echo 0 is for detach, echo 1 is for attaching. Also Muta didn't add the line ```<hidden state='on'/>```, but in some case it's necessary (like in my case).
    
- remember to "study" how to manage `.qcow2` disk images. For example [resizing](https://linuxconfig.org/how-to-resize-a-qcow2-disk-image-on-linux) is very useful to not occupy disk space uselessly. Using `libguestfs-tools` you can obtain similar results: 
```shell
du -h win11_gaming.qcow2
57.9G win11_gaming.qcow2

sudo virt-sparsify --in-place win11_gaming.qcow2
[   5.7] Trimming /dev/sda1
[   5.8] Trimming /dev/sda3
[   9.8] Trimming /dev/sda4
[   9.9] Sparsify in-place operation completed with no errors

du -h win11_gaming.qcow2
19G	win11_gaming.qcow2
```
