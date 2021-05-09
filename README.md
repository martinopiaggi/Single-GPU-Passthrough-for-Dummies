# Single GPU Passthrough for Dummies

### Why

If you want to achieve VFIO/IOMMU gpu passthrough without buying a second gpu or with Mini-ITX build with no iGPU. 
Note that this solution is very similar to a dual boot. 

### Hardware and Software:
Successfully tested on:
mobo: Asus Strix X570-I (itx)
cpu: Ryzen 3900x
gpu: gtx 1070ti Msi Armor 
host os: Arch Linux Manjaro
guest os: Windows 10

# Steps from zero to working KVM:

1. [Basic prep Wiki Arch](##BasicPrep) 
2. [Patched vbios](##Patched VBIOS)
3. [Hook manager and scripts](##hookmanager)
4. [Running the VM](##RunningtheVM)
5. [Extra video tutorial](##Extra,videotutorial)

Yes, as you noticed the fifth step is a video tutorial. A video that I find pretty useful. However there are little imperfections that maybe cause you some troubles. Check the [video tutorial step](#Extra: video tutorial) for more info. 

## Basic prep
In my opinion there isn't a guide more complete that the [Wiki Arch](https://wiki.archlinux.org/title/PCI_passthrough_via_OVMF) one.  
You have to do **only these steps** to successfully run the VM:
-   [1 Prerequisites](https://wiki.archlinux.org/title/PCI_passthrough_via_OVMF#Prerequisites)
-   [2 Setting up IOMMU](https://wiki.archlinux.org/title/PCI_passthrough_via_OVMF#Setting_up_IOMMU) 
-   [2.1 Enabling IOMMU](https://wiki.archlinux.org/title/PCI_passthrough_via_OVMF#Enabling_IOMMU)
-   [2.2 Ensuring that the groups are valid](https://wiki.archlinux.org/title/PCI_passthrough_via_OVMF#Ensuring_that_the_groups_are_valid)
-   [4 Setting up an OVMF-based guest VM](https://wiki.archlinux.org/title/PCI_passthrough_via_OVMF#Setting_up_an_OVMF-based_guest_VM)
-   [4.1 Configuring libvirt](https://wiki.archlinux.org/title/PCI_passthrough_via_OVMF#Configuring_libvirt)
-   [4.2 Setting up the guest OS](https://wiki.archlinux.org/title/PCI_passthrough_via_OVMF#Setting_up_the_guest_OS)
-   [4.3 Attaching the PCI devices](https://wiki.archlinux.org/title/PCI_passthrough_via_OVMF#Attaching_the_PCI_devices)
-   [4.4 Video card driver virtualisation detection](https://wiki.archlinux.org/title/PCI_passthrough_via_OVMF#Video_card_driver_virtualisation_detection)

Ok, you should arrive in this step with a working guest VM without any GPU passed. 
## Patched VBIOS
Some GPUs need to be patched to be passed. Find the vbios of your GPU [here](https://www.techpowerup.com/vgabios/). You need to patch the .rom file with an Hex Editor. I used [bless](https://aur.archlinux.org/packages/bless-git/). You have to open the .rom with bless, then delete every character before a specific ``  U``  . To find the right ``  U``   simply use the finder tool built in the Hex Editor with  ``  VIDEO``   as keyword.   After you have found the **first** ``  VIDEO``    , you have to delete every character before the ``   U ``   that immediately precedes the ``  VIDEO``   you have just found. 
This is an example on how the first line of the vbiosPATCHED.rom should start: ```  U...K7400.L.w.VIDEO```   . 
*note that maybe some bios file from techpowerup.com are already patched. This .rom are uploaded by users and you can identify them because they are not listed entries of the main table and there is a warning banner on their page. Anyway they should work.*
Save the patched .rom anywhere. 

## Hook Manager and scripts
Now it's time for the vfio-Tools Hook Helper. This is the tool which starts the necessary scripts for GPU passing. Install the vfio-tools hook helper using [this guide]((https://passthroughpo.st/simple-per-vm-libvirt-hooks-with-the-vfio-tools-hook-helper/)). 
You need to make the directories ```  /etc/libvirt/hooks/qemu.d/{your VM Name}/prepare/begin```    and ```   /etc/libvirt/hooks/qemu.d/{your VM Name}/release/end ```   .
Anything in the ```  begin```    directory will start when your VM is launched while everything in the ```  end```   directory will run when the VM is stopped.
Copy and modify the ```  start.sh```   and the ```  revert.sh```   scripts in (respectively) folders. 
The scripts are very simply to modify and they are for a Nvidia card like mine. Read the comments to modify properly the scripts.

## Running the VM
Ok, before running the VM,  pass all the PCI devices related to your GPU with the configuration window of Virtual Machine Manager. It's important that you have done the [4.3](https://wiki.archlinux.org/title/PCI_passthrough_via_OVMF#Attaching_the_PCI_devices) and [4.4](https://wiki.archlinux.org/title/PCI_passthrough_via_OVMF#Video_card_driver_virtualisation_detection) of the Arch Wiki Guide that I adviced to follow in the first step of this guide. 
Now it's time for the .rom file of your GPU firmware. After adding all the PCI devices related to your GPU and after enabling the XML editing in virt-manager (open virt-manager>edit>preferences>general>enable xml editing) you have to edit the XML of your PCI devices. Add ```  <rom file = '/file/path/where/do/you/put/the/patched.rom'/>```   between the line ```  </source>```   and ```  <address ...>```  .
 At this point everything is ready to run. After some tests you could eventually reducing the timer.

## Extra, video tutorial
You can integrate this guide with this [video](https://www.youtube.com/watch?v=BUSrdUoedTo&t=2401s) . From ```  12:04```   the video is aligned with the second step of this guide. The video is very usefull and complete but there are little imperfections: 
- in the ```  revert.sh```   Muta (the youtuber) has accidentally wrote echo 1 instead of echo 0. Remember that Echo 0 is for detach, echo 1 is for attaching.
- in the [4.4](https://wiki.archlinux.org/title/PCI_passthrough_via_OVMF#Video_card_driver_virtualisation_detection) of the Arch Wiki Guide suggest to edit the XML adding the line ```  <hidden state='on'/>```   . Muta didn't add this, but in some case it's necessary (like in my case. In fact, without that line my win10 doesn't start).
    
### Special Thanks to: [Muta](https://www.youtube.com/channel/UCtMVHI3AJD4Qk4hcbZnI9ZQ) who made the funniest tutorial ever about this topic. 
