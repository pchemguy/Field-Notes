# Storage Considerations for a New PC, Part 2: Building a Bootable USB Drive

## 1. Introduction

In [Part 1](https://github.com/pchemguy/Field-Notes/blob/main/02-storage-new-pc/README.md) of this series, we designed a resilient internal storage partitioning scheme for a new Windows workstation, starting from a blanked drive. Partitioning the system drive and performing a clean installation of an operating system requires an external, bootable medium. This guide covers the process of creating that essential tool: a versatile, multi-boot USB drive. The primary goal is preparing a bootable drive supporting a full "Windows To Go" environment and Windows installation. For added flexibility, we require the ability to boot other distributions as well, such as system recovery tools and Linux live booting and installation. Further, fast SSD drives are preferable for such a job due to both speed and space considerations. At the same time, because I need a bootable drive primarily for the purposes described, I only need a few bootable images to fulfil them. Since it does not make much sense to buy a small SSD, the other requirement for this tool is to also serve as an external backup drive. And both of these functions - multi-booting and backup - should be conveniently provided without any compromises.

## 2. Defining Boot Targets

First, we need to define what this drive must be capable of booting. The goal is to consolidate a variety of installation and recovery tools onto a single medium.

| Name                    | Source                                            | Image Size (GB) |
| ----------------------- | ------------------------------------------------- | --------------: |
| Windows 10 ToGo         | Bootable VHD(X), see "Windows ToGo" section       |            10.0 |
| Windows 10 Install      | Official Installation ISO                         |             5.0 |
| Ubuntu 24.04 LTS        | Official Installation ISO                         |             5.9 |
| SystemRescue            | https://system-rescue.org                         |             1.1 |
| Lazesoft Recovery Suite | https://lazesoft.com/lazesoft-recovery-suite.html |             0.3 |
| Hiren’s BootCD PE       | https://hirensbootcd.org                          |             3.1 |
| Sergei Strelec WinPE    | https://sergeistrelec.name                        |             3.2 |

Total minimum space requirement: 29 GB.

## 3. Choosing the Right Tool: A Comparison of Select Drive Creators

Several excellent utilities can create bootable USB drives, but they fall into two main categories: single-boot and multi-boot. While a single-boot tool like Rufus is fast and reliable for creating one-off installers, our goal requires a multi-boot solution.

| Name            | Multi-bootable | Key Feature                                                                   | Source                         |
| --------------- | :------------: | ----------------------------------------------------------------------------- | ------------------------------ |
| Rufus           |       No       | The standard for fast, single-ISO flashing.                                   | https://rufus.ie               |
| Ventoy          |      Yes       | Drag-and-drop ISOs directly onto the drive.                                   | https://ventoy.net             |
| YUMI exFAT      |      Yes       | GUI-based manager built on Ventoy.                                            | https://yumiusb.com/yumi-exfat |
| Easy2Boot (E2B) |      Yes       | Highly customizable, powerful boot manager (grub4dos, grub2, Ventoy for E2B). | https://easy2boot.xyz          |

For optimum flexibility and ease of use, Ventoy is the clear winner. Its ability to boot directly from `.ISO` and `.VHD(X)` files that you simply drag and drop onto the drive makes it incredibly simple to manage and update your toolkit. YUMI exFAT is a user-friendly alternative that uses Ventoy as its underlying technology. While Easy2Boot provides even more advanced features, thus functionality comes at the cost of more complicated workflows and is unnecessary in this case. 

## 4. The Blueprint: A Ventoy-Based Multi-Boot Drive

The remainder of this guide will focus on creating a dual purpose (bootable/archival) external SSD using the Ventoy/YUMI exFAT method. This approach allows us to have a dedicated partition for bootable images while reserving the rest of the drive for other uses, such as portable applications or file archives. Such a clear separation of functionalities ensures that they will not interfere with each other. 

### Understanding the Ventoy Partition Scheme

Ventoy works by creating two specific partitions at the beginning of the drive:
1. **The Main Data Partition:** This is a large, standard partition visible to your OS. You simply copy your `.ISO`, `.VHD`, and other image files here. While YUMI labels this "YUMI", Ventoy leaves it unlabeled.
2. **The EFI System Partition (`VTOYEFI`):** This is a small (32 MB), hidden partition that contains the bootloader files. It is created automatically and should not be modified.

Crucially, modern versions of Ventoy allow these two partitions to exist without occupying the entire drive, leaving the remaining space free for you to create and manage your own additional partitions (see [MBR](https://ventoy.net/en/doc_disk_layout.html#reserve_space) and [GPT](https://ventoy.net/en/doc_disk_layout_gpt.html#reserve_space) for further details).

### Step-by-Step Drive Preparation

While YUMI exFAT can prepare a drive, it offers limited options compared to Ventoy. The most flexible approach, however, is to partition the drive manually first and then perform a ["Non-destructive Install"](https://ventoy.net/en/doc_non_destructive.html) of Ventoy. Here is an example disk layout:

| Partition         | Anticipated Usage (GB) | Planned Allocation (GB) | Unallocated Space (GB) |
| ----------------- | ---------------------: | ----------------------: | ---------------------: |
| YUMI              |                     30 |                      40 |                      - |
| VTOYEFI           |                      - |                       - |                     80 |
| Portable Programs |                     40 |                      50 |                     20 |
| Archive           |               Variable |         Remaining space |                      - |

If you wish to use the YUMI exFAT interface for managing your ISOs, the process is slightly more complex:
1. **Initial Prep:** Use YUMI exFAT to prepare the target drive once. This creates the necessary configuration directories.
2. **Save Config:** Copy the `YUMI` and `ventoy` directories from the drive's main partition to a temporary location on your computer.
3. **Manual Partitioning:** Use a tool like Windows Disk Management or `diskpart` to wipe the drive and create your desired custom partition layout.
4. **Install Ventoy:** Run the Ventoy2Disk tool and use the "Non-destructive Install" option on your newly partitioned drive. This will create the small EFI partition without erasing your custom layout.
5. **Restore Config:** Label the first partition "YUMI" and copy the two directories you saved in Step 2 back onto it.
6. **Manage ISOs:** You can now use the YUMI exFAT GUI to add and remove bootable distributions, or simply drag and drop ISO files onto the "YUMI" partition yourself.

> [!WARNING]
> 
> **Important Ventoy2Disk Notes:**
>  
> - To see internal or non-USB drives, you must select **Options -> Show All Devices**.
> - The **Options -> Non-destructive Install** menu item is an action that **immediately begins the installation**, not a setting you can toggle. Ensure you have the correct device selected _before_ clicking it.

As discussed in [Part 1](https://github.com/pchemguy/Field-Notes/blob/main/02-storage-new-pc/README.md), unallocated space serves two purposes: provides a reserve pool for future expansion of the preceding partition and is used for SSD over-provisioning while remains unallocated. In this case, however, reserving unallocated space immediately after the "YUMI" partition is impossible due to Ventoy restrictions. For this reason, the extra space is left after "VTOYEFI" partition. If the "YUMI" needs to be expanded, the system "VTOYEFI" partition is deleted first using diskpart (Windows Disk Manager (WDM) will not delete system partitions). Then the "YUMI" partition is extended using either diskpart or WDM. Finally, the "VTOYEFI" partition is recreated via a "Non-destructive Install" of Ventoy. If necessary, the last partition can be shrunk to compensate for decreased amount of unallocated space available for SSD over-provisioning.

### 5. Special Case: Adding a Windows To Go Environment

A "Windows To Go" (WTG) installation - a full, bootable Windows environment running from your USB drive - might be useful as an alternative emergency boot environment, as well as when you need to work on someone else's computer. For multi-boot environment, WTG is typically created as a bootable virtual hard disk (`.VHDX`) file that you place on your Ventoy partition. While Microsoft discontinued official support for WTG, several tools can use Windows Installation ISO and some alternative sources for creation of equivalent WTG environment:

| Tool                                               | Source                     | Destination                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    |
| -------------------------------------------------- | -------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| [Rufus](https://rufus.ie)                          | Windows Installation ISO   | - USB stick  <br>- Mounted VHD(X) virtual drive  <br>- USB SSD/HDD (press Alt+F to show in the list)  <br>- Internal drive, including virtual drives within a virtual PC<br>  ([press](https://superuser.com/a/1337432) Ctrl+Alt+F to show in the list)  <br>  Note that virtual drives within a virtual PC include<br>    - standard virtual drives<br>    - passed through drives connected to the host<br>        - physical<br>        - USB (presented as a regular disk, unless USB emulation is configured)<br>        - mounted VHD(X) |
| [WinToUSB](https://easyuefi.com/wintousb)          | ISO, WIM, ESD, SWM, VHD(X) | USB (any type)                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                 |
| [ISO2Disc](https://top-password.com/iso2disc.html) | Windows Installation ISO   | USB (any type)                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                 |
Note: this table shows tested and/or officially documented sources/destinations. It does not attempt to include every documented options, so additional options may be available. Check official documentation for more information.

#### Bootable VHD(X) Creation  

WinToUSB provides the broadest spectrum of supported sources. At the same time, it only supports USB drives as its target, a physical (or virtual within a virtual machine) USB drive needs to be used as an intermediate target. After WTG is installed, a VHD(X) image can be created, e.g., with [Sysinternals Disk2vhd](https://learn.microsoft.com/en-us/sysinternals/downloads/disk2vhd). Rufus, on the other hand, only supports the standard (possibly also customized) Windows Installation ISO as the source, but it can install WTG on virtually any target, physical or virtual, supporting direct installation onto a mounted VHD(X) image.

**Rufus-based Workflow**
It is generally a good idea to troubleshoot and test bootable images and a bootable tool within a virtual machine before proceeding to real tests. With Rufus and VMWare, preliminary work can be done without any physical drives involved:
1. Create a new VHDX file using diskpart or WDM.
2. Mount the new image on the host system.
3. Use Rufus to install WTG.
4. In VMWare, create a new virtual disk, using a physical host disk and selecting the mounted VHDX as the source.
5. Boot VMWare from this virtual disk.
6. Finish configuration, adjust any necessary settings, install drivers and essential software.
7. Shutdown VM, remove virtual disk, unmount VHDX from the host.
8. Add VHDX to the bootable disk via YUMI exFAT or directly (this can be a virtual disk at early stages and physical USB SSD at later stages).
9. Boot VM into WTG using bootable disk (virtual disk or passed through USB disk).
10. Boot a physical computer using a bootable USB SSD.

> {!NOTE}
> 
> When booted from VHDX, Windows will most likely run in non persistent mode. Other USB disk partition will need to be used for permanent changes.

### 6. Conclusion

By following this guide, you have transformed a standard external drive into a powerful, versatile tool. This bootable medium allows you to implement the advanced storage architecture we designed in [Part 1](https://github.com/pchemguy/Field-Notes/blob/main/02-storage-new-pc/README.md), perform clean OS installations, boot to portable configured Windows environment, conduct system maintenance, and recover from failures. At the same time, this disk also serves as a backup storage.
