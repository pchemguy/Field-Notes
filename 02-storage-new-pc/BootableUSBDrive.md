# Storage Considerations for a New PC, Part 2: Building a Dual-Purpose, Bootable USB Drive

![](https://raw.githubusercontent.com/pchemguy/Field-Notes/refs/heads/main/02-storage-new-pc/vis2.jpg)

## Summary

This guide provides a step-by-step walkthrough for creating the essential tool for any power user: a versatile, multi-boot external SSD. We move beyond simple installers to build a dual-purpose "digital Swiss Army knife" that can boot a wide array of recovery tools while also serving as a portable drive for backups and applications.

The core of this project is Ventoy, a powerful tool that allows you to boot directly from `.ISO` and `.VHDX` files by simply dragging and dropping them. The guide focuses on using Rufus and YUMI exFAT tools in combination with standard Windows disk management tools for creating a custom partition layout for a dual-purpose drive and adding a Windows To Go environment. By the end, you will have a single, indispensable tool for system installation, maintenance, and recovery.

## 1. Introduction

In [Part 1](https://github.com/pchemguy/Field-Notes/blob/main/02-storage-new-pc/README.md) of this two-part series, we designed a resilient internal storage scheme for a new Windows workstation, a process that begins with a clean drive. Implementing that strategy requires an external, bootable medium to partition the system drive and perform a clean installation of the operating system. This guide covers the process of creating that essential tool: a versatile, multi-boot USB drive. The primary requirements are to support a full Windows To Go environment and standard Windows installation media, with the flexibility to boot other tools like system recovery suites and live Linux distributions.

A fast external Solid State Drive (SSD) is the ideal hardware for this task due to its speed and reliability. Since small-capacity SSDs are often poor value, a larger drive is more practical. This leads to our second core requirement: the drive must serve a dual purpose. It needs to function as our powerful multi-boot tool while the remaining space serves as a general-purpose drive for backups or portable applications. The goal is to achieve both of these functions on a single device without compromise.

## 2. Defining Boot Targets

Before building our drive, we must define its purpose. The goal is to create a "digital Swiss Army knife" by consolidating a curated set of installation, recovery, and utility environments onto a single, portable medium. The chosen tools will form our bootable library. Here is the list of essential boot targets for this project:

| Name                    | Source                                            | Image Size (GB) |
| ----------------------- | ------------------------------------------------- | --------------: |
| Windows 10 ToGo         | Bootable VHD(X), see "Windows ToGo" section       |            15.0 |
| Windows 10 Install      | Official Installation ISO                         |             5.0 |
| Ubuntu 24.04 LTS        | Official Installation ISO                         |             5.9 |
| SystemRescue            | https://system-rescue.org                         |             1.1 |
| Lazesoft Recovery Suite | https://lazesoft.com/lazesoft-recovery-suite.html |             0.3 |
| Hiren’s BootCD PE       | https://hirensbootcd.org                          |             3.1 |
| Sergei Strelec WinPE    | https://sergeistrelec.name                        |             3.2 |

This versatile collection requires approximately 35 GB of dedicated space. Now that we know _what_ we need to boot, the next step is to choose the right tool to build our multi-boot drive.

## 3. Choosing the Right Tool: A Comparison of Select Drive Creators

Several established utilities can create bootable USB drives, but they fall into two main categories: single-boot and multi-boot. While a single-boot tool like Rufus is fast and reliable for creating one-off installers, our goal of consolidating multiple tools requires a multi-boot solution.

| Name            | Multi-bootable | Key Feature                                                                                               | Source                         |
| --------------- | :------------: | --------------------------------------------------------------------------------------------------------- | ------------------------------ |
| Rufus           |       No       | The industry standard for fast, single-ISO flashing.                                                      | https://rufus.ie               |
| Ventoy          |      Yes       | Drag-and-drop ISOs directly onto the drive.                                                               | https://ventoy.net             |
| YUMI exFAT      |      Yes       | A GUI-based manager built on Ventoy.                                                                      | https://yumiusb.com/yumi-exfat |
| Easy2Boot (E2B) |      Yes       | A highly customizable and powerful boot manager for advanced use cases (grub4dos, grub2, Ventoy for E2B). | https://easy2boot.xyz          |

For the optimal balance of flexibility and ease of use, Ventoy is the clear winner. Its ability to boot directly from .ISO and .VHDX files - which you simply drag and drop onto the drive's main partition - makes managing and updating your toolkit incredibly simple.

YUMI exFAT is a user-friendly alternative that uses Ventoy as its underlying technology, offering a more guided, graphical interface for managing distributions. While tools like Easy2Boot provide even more advanced features, this power comes with a more complex workflow and is unnecessary for the goals outlined in this guide.

## 4. The Blueprint: A Ventoy-Based Multi-Boot Drive

The remainder of this guide will focus on creating a dual-purpose (bootable and archival) external SSD using the Ventoy method. This approach allows us to create a dedicated partition for bootable images while reserving the rest of the drive for other uses, such as portable applications or file archives. This clear separation ensures that the drive's functions will not interfere with each other.

### Understanding the Ventoy Partition Scheme

Ventoy works by creating two specific partitions at the beginning of the drive:
1. **The Main Data Partition:** A large, standard partition visible to your OS where you simply copy your bootable image files. It can hold `.ISO` files, `.WIM` images, and more. For booting from virtual disks like `.VHDX` (used for Windows To Go), this partition **should be formatted as NTFS** instead of the default exFAT (depending on Windows version, booting Windows To Go from a `.VHDX` file on exFAT [may or may not work](https://ventoy.net/en/plugin_vhdboot.html)).
    - _Note: By default, the Ventoy tool labels this partition "Ventoy", while YUMI exFAT labels it "YUMI". This label is purely informational and can be changed as needed._
2. **The EFI System Partition (`VTOYEFI`):** A small (32 MB), hidden partition containing the bootloader files. It is created automatically by the installer and should not be modified.

Crucially, modern versions of Ventoy allow these two partitions to exist without occupying the entire drive, leaving the remaining space free for you to create your own additional partitions (see the official documentation for [MBR](https://ventoy.net/en/doc_disk_layout.html#reserve_space) and [GPT](https://ventoy.net/en/doc_disk_layout_gpt.html#reserve_space) layouts). We will leverage this feature for creation of our custom, multi-purpose drive.

### Step-by-Step Drive Preparation

While tools like YUMI exFAT can prepare a drive, they offer limited options. A more flexible approach is to partition the drive manually and then perform a ["Non-destructive Install"](https://ventoy.net/en/doc_non_destructive.html) of Ventoy, giving you full control over the final disk layout.

There are two main ways to achieve custom disk layout: a simpler method relies on the standard GUI tools only, and an advanced method for users who require precise low-level control.

**Recommended Workflow: The "Shrink and Reinstall" Method**

This method is simpler as it leverages Ventoy's automatic configuration and the user-friendly Windows Disk Management (WDM) tool.

1. **Initial Setup:** Run `Ventoy2Disk.exe` and perform a standard, destructive installation on your target drive, creating the correctly aligned `Ventoy` and `VTOYEFI` partitions.
2. **Open Disk Management:** Open WDM by running `diskmgmt.msc`.
3. **Prepare for Customization:**
    - Right-click the small `VTOYEFI` partition and select "Delete Volume."
    - Right-click the main `Ventoy` data partition and format it as **NTFS**. This is a required step, as WDM cannot resize non-NTFS partitions like exFAT.
4. **Create Your Layout:**
    - Right-click the now-NTFS `Ventoy` partition and shrink it to your desired size (e.g., 40 GB).
    - Right-click the new unallocated space and create your additional partitions (`PortablePrograms`, `Archive`, etc.) as needed.
5. **Finalize Ventoy:** Run `Ventoy2Disk.exe` one last time and perform a **"Non-destructive Install"**. Ventoy will seamlessly recreate the `VTOYEFI` partition without harming your new custom layout.

> [!NOTE]
> 
> **WDM Note**
> 
> When using WDM, the actual size of the created partition is apparently increased (compared to indicated value) by the size of file system structures. For precise control, `diskpart` would need to be used.
> 
> **Using YUMI for Distro Management**
> 
> If you wish to use the YUMI exFAT GUI for managing bootable distros, you need to perform these steps.
> 
> - Instead of the **Step 1** above, use YUMI to format the drive once, then copy the "YUMI" and "ventoy" directories to your computer from the created YUMI data partition.
> - After completing the workflow above, copy these two directories back onto your main data partition.
> 
> **Secure Boot**
> 
> See [Ventoy Secure Boot information](https://ventoy.net/en/doc_secure.html)

**Advanced Workflow: Manual `diskpart` Initialization**

> [!WARNING]
> 
> **Critical `diskpart` Considerations**
> 
> - **Partition Alignment:** When creating partitions manually with `diskpart`, you must ensure the first partition is aligned at a 1 MB offset, as required by Ventoy. Ventoy/YUMI do this alignment automatically, but with `diskpart` it is a manual requirement.
> - **MSR Partition:** If your drive has a hidden Microsoft Reserved Partition (MSR), it will not be visible in WDM. It can only be viewed and deleted using `diskpart`.

The primary difference of these "diskpart"-based approach is the necessity to manually delete the MSR partition, if present, and ensure that the first (main data) partition to be used by Ventoy/YUMI is aligned at 1 MB (the **Step 1**). The rest of the workflow can be performed as outlined above using WDM, or the entire partitioning process can be completed in `diskpart`.    

### Example Layout and Advanced Management

The real power of this method is the ability to create a completely custom layout. Here is a sample blueprint for a multi-purpose SSD:

| Partition         | Anticipated Usage (GB) | Planned Allocation (GB) | Unallocated Space (GB) |
| ----------------- | ---------------------: | ----------------------: | ---------------------: |
| YUMI              |                     30 |                      50 |                      - |
| VTOYEFI (hidden)  |                      - |                       - |                     80 |
| Portable Programs |                     40 |                      50 |                     20 |
| Archive           |               Variable |         Remaining space |                      - |

Notice the unallocated space is strategically placed. As discussed in [Part 1](https://github.com/pchemguy/Field-Notes/blob/main/02-storage-new-pc/README.md), this space serves as a buffer for partition expansion and as SSD over-provisioning. However, Ventoy has a restriction: its main data partition (YUMI) and the VTOYEFI partition must be adjacent. This restriction means we cannot leave unallocated space directly after the YUMI partition. The workaround is to place the reserve space _after_ the VTOYEFI partition. If you ever need to expand the YUMI partition, use the following workflow:
1. **Delete the EFI Partition:** Use `diskpart` to delete the VTOYEFI partition (WDM will not allow this step).
2. **Extend the Main Partition:** Use WDM or `diskpart` to extend the YUMI partition into the now-adjacent unallocated space.
3. **Recreate the EFI Partition:** Run `Ventoy2Disk` and perform another "Non-destructive Install". Ventoy will automatically recreate the VTOYEFI partition in the correct location.

### 5. Special Case: Adding a Windows To Go Environment

A "Windows To Go" (WTG) installation - a full, bootable Windows environment running from your USB drive - might be useful for emergencies or when you need to work on a guest computer. For multi-boot disks, the WTG environment is typically created as a single bootable virtual hard disk (`.VHDX`) file that you place on the Ventoy partition.

> [!IMPORTANT]
> 
> - By default, Ventoy and YUMI format the main data partition as **exFAT**. While broadly compatible, Ventoy may not be able to boot WTG ([depending on Windows version](https://ventoy.net/en/plugin_vhdboot.html)) from a `.VHDX` file on an **exFAT** partition, requiring **NTFS** file system instead. Before you proceed, ensure the partition that will hold your bootable images (e.g., "YUMI") is formatted as **NTFS**.
> - To boot WTG from a `.VHDX` file, Ventoy requires [Windows VHD Boot Plugin](https://ventoy.net/en/plugin_vhdboot.html), which must be installed separately. The downloaded and extracted `ventoy_vhdboot.img` plugin needs to be placed inside the `ventoy` directory created by YUMI exFAT or manually on the main data partition.

While Microsoft has discontinued official support for WTG, several third-party tools can create an equivalent environment from a Windows Installation ISO.

| Tool                                               | Source Formats             | Destination Flexibility                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        |
| -------------------------------------------------- | -------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| [Rufus](https://rufus.ie)                          | Windows Installation ISO   | - USB stick  <br>- Mounted VHD(X) virtual drive  <br>- USB SSD/HDD (press Alt+F to show in the list)  <br>- Internal drive, including virtual drives within a virtual PC<br>  ([press](https://superuser.com/a/1337432) Ctrl+Alt+F to show in the list)  <br>&nbsp;&nbsp; Note that virtual drives within a virtual PC include<br>&nbsp;&nbsp;&nbsp;&nbsp; - standard virtual drives<br>&nbsp;&nbsp;&nbsp;&nbsp; - passed through drives connected to the host<br>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp; - physical<br>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp; - USB (presented as a regular disk, unless USB emulation is configured)<br>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp; - mounted VHD(X) |
| [WinToUSB](https://easyuefi.com/wintousb)          | ISO, WIM, ESD, SWM, VHD(X) | USB (any type)                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                 |
| [ISO2Disc](https://top-password.com/iso2disc.html) | Windows Installation ISO   | USB (any type)                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                 |

Note: this table shows tested and/or officially documented sources/destinations. It does not attempt to include every documented option, so additional options may be available. Check official documentation for more information.

#### Creating the Bootable VHDX

While WinToUSB offers the broadest support for source files, Rufus provides the most flexible destination options, allowing us to install WTG directly onto a virtual disk file without needing an intermediate physical drive. The following workflow details how to create and test your WTG image within a virtual machine before deploying it to the physical USB drive.

1. **Create VHDX:** Use WDM or `diskpart` to create a new `.VHDX` file on your computer.    
2. **Mount VHDX:** Mount the new `.VHDX` file so it appears as a regular drive in Windows.
3. **Install WTG with Rufus:** Run Rufus, select your Windows Installation ISO, and choose the mounted VHDX drive as the destination. Proceed with the WTG installation.
4. **Initial VM Setup:** In VMware or your preferred hypervisor, create a new virtual machine that boots from a physical disk, pointing it to your mounted `.VHDX`-based disk.
5. **Configure Windows:** Boot the new VM. Complete the initial Windows setup (OOBE), install critical drivers, and make any desired software installations or configuration changes within the virtualized WTG environment.
6. **Finalize and Test:**
    - Shut down the VM and unmount the `.VHDX` from your host system.
    - Copy the finalized `.VHDX` file to the main data partition of your Ventoy USB drive (or use YUMI exFAT).
    - Test it by booting a VM and your physical computer from the Ventoy drive and selecting the VHDX file from the boot menu.

> [!NOTE]
> 
> - When booted from a VHDX, Windows will run in a non-persistent mode, meaning changes are not saved back to the `.VHDX` file upon shutdown. For persistent storage, you must save files to one of the other visible partitions on your USB drive, such as your `Archive`  partition.
> - When using Rufus to create WTG, Rufus by default sets the "Prevent Windows To Go from accessing internal disks" option, which, in turn, sets [storage area network policy](https://learn.microsoft.com/en-us/windows-hardware/manufacture/desktop/winpe-storage-area-network--san--policy) ([also](https://learn.microsoft.com/en-us/windows-server/administration/windows-commands/san)) to 4 (value of "1" enables disks), setting internal disks to offline at boot (Windows registry setting:  
>   `reg add "HKLM\SYSTEM\CurrentControlSet\Services\partmgr\Parameters" /f /t REG_DWORD /d 4 /v "SanPolicy"`
> - VHD(X) image can also be created from a physical disk using tools like [Sysinternals Disk2vhd](https://learn.microsoft.com/en-us/sysinternals/downloads/disk2vhd).

### 6. Conclusion

With the completion of this bootable drive, our two-part guide is now finished. You have not only designed a resilient internal storage architecture but also built the powerful, versatile tool required to deploy and maintain it.

This single external drive now enables you to:
- Implement the custom partitioning strategy from [Part 1](https://github.com/pchemguy/Field-Notes/blob/main/02-storage-new-pc/README.md).
- Perform clean installations of Windows or Linux.
- Boot into a portable, configured Windows To Go environment.
- Run a comprehensive suite of system recovery and diagnostic tools.
- Serve as a general-purpose drive for backups and archives.

Your digital Swiss Army knife is complete, providing a robust foundation for a more resilient and manageable computing experience.
