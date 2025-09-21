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

Crucially, modern versions of Ventoy allow these two partitions to exist without occupying the entire drive, leaving the remaining space free for you to create and manage your own additional partitions.

### Step-by-Step Drive Preparation

While YUMI exFAT can prepare a drive, it offers limited options compared to Ventoy. The most flexible approach, however, is to partition the drive manually first and then perform a "Non-destructive Install" of Ventoy. Here is an example disk layout:

| Partition         | Anticipated Usage (GB) | Planned Allocation (GB) | Unallocated Space (GB) |
| ----------------- | ---------------------: | ----------------------: | ---------------------: |
| YUMI              |                     30 |                      40 |                      - |
| VTOYEFI           |                      - |                       - |                     80 |
| Portable Programs |                     40 |                      50 |                     20 |
| Archive           |               Variable |         Remaining space |                      - |
As discussed in [Part 1](https://github.com/pchemguy/Field-Notes/blob/main/02-storage-new-pc/README.md), unallocated space serves two purposes: provides a reserve pool for future expansion of the preceding partition and is used for SSD over-provisioning while remains unallocated. 

If you wish to use the YUMI exFAT interface for managing your ISOs, the process is slightly more complex:
1. **Initial Prep:** Use YUMI exFAT to prepare the target drive once. This creates the necessary configuration directories.
2. **Save Config:** Copy the `YUMI` and `ventoy` directories from the drive's main partition to a temporary location on your computer.
3. **Manual Partitioning:** Use a tool like Windows Disk Management or `diskpart` to wipe the drive and create your desired custom partition layout.
4. **Install Ventoy:** Run the Ventoy2Disk tool and use the "Non-destructive Install" option on your newly partitioned drive. This will create the small EFI partition without erasing your custom layout.
5. **Restore Config:** Label the first partition "YUMI" and copy the two directories you saved in Step 2 back onto it.
6. **Manage ISOs:** You can now use the YUMI exFAT GUI to add and remove bootable distributions, or simply drag and drop ISO files onto the "YUMI" partition yourself.

> [!Warning]
> 
> Important Ventoy2Disk Notes:
>  
> - To see internal or non-USB drives, you must select **Options -> Show All Devices**.
> - The **Options -> Non-destructive Install** menu item is an action that **immediately begins the installation**, not a setting you can toggle. Ensure you have the correct device selected _before_ clicking it.

### 5. Special Case: Adding a Windows To Go Environment

One of the most powerful boot targets is a "Windows To Go" (WTG) installation—a full, bootable Windows environment running from your USB drive. This is typically created as a bootable virtual hard disk (`.VHDX`) file that you place on your Ventoy partition.

Two excellent tools for this are **Rufus** and **Hasleo WinToUSB**. Both can take a standard Windows Installation ISO and install it as a WTG environment onto a target drive.

|Tool|Source Formats|Destination|
|---|---|---|
|**Rufus**|Windows Installation ISO|USB Drive, Mounted VHD(X)|
|**Hasleo WinToUSB**|ISO, WIM, ESD, SWM, VHD(X)|Any USB Drive|

The easiest way to create a bootable `.VHDX` file for Ventoy is to:

1. Create and mount a new virtual disk (`.VHDX`) in Windows Disk Management.
    
2. Use Rufus or Hasleo WinToUSB to perform a Windows To Go installation, targeting the mounted virtual disk as the destination.
    
3. Once complete, unmount the virtual disk and copy the resulting `.VHDX` file to your Ventoy partition.
    

---

### 6. Conclusion

By following this guide, you have transformed a standard external drive into a powerful, versatile tool. This bootable medium is the key that unlocks the advanced storage architecture we designed in Part 1, allowing you to perform clean installations, conduct system maintenance, and recover from failures with confidence. Your new digital Swiss Army knife is ready for action. 🧰