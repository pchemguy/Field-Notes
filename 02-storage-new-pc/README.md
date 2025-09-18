# Storage Considerations for a New PC

The following considerations primarily apply to Windows systems, though they might be applicable to other systems as well. They also focus on management of a standalone individually-managed personal workstation, and may be less relevant to commercially used computers managed as a part of business's IT resources. 

When planning a purchase of a new computer, there are several storage-related considerations to be considered.
- Cloud Backup
   The files I actively work on are backed up in the cloud (basic direct cloud backup or using a version control system). An important advantage of VCS over basic direct backup is that accidentally damaged files would not overwrite the backed up copy. The same advantage applies to encrypting ransomware attacks: it would be quite hard for ransomware to affect backed up copies stored in a cloud VCS repository.
- External Drive
    -  Infrequent Backups / Archives
      A good, fast, and spacious HDD should work just fine. Presently I use a pair of 4 TB HDD drives to host two copies of mostly the same content.
    - Dual Bootable and Active Backups
      A good SSD drive is better suitable for scenarios where the drive is used for emergency booting, operating system installation, as well as for daily backups.
- Internal Drives
  It might be a good idea to have at least two internal drives: an SDD and HDD. Operating system, program files, and the master copy of data may be kept on a 2.5" internal SSD or M2 NVMe drive. HDD may hold downloads, local backups, perhaps, the temp directory (?), software distros, other resources that might be handy to have locally, such as libraries.
  
  In the case of a dual boot system (especially incompatible, such as Windows and Linux), it is worth considering placing each OS on its own dedicated SSD (that is having two SSDs). In special cases, where a very fast storage is necessary for computational purposes, the fastest available M2 NVMe drive should be installed in the matching fastest interface and be dedicated exclusively for computational purposes, while placing OS(s) on separate SSDs as before.

## Partitioning Internal System SSD

A major advantage of having a single partition is not having to worry about provisioning enough space on individual partitions yet avoiding inefficient drive use due to excessive unused/fragmented free space. Historically, my primary motivation for partitioning the drive was ensuring efficient data integrity workflow and robust recovery in case of system corruption or worse complete failure of the drive. Because data recovery from a failed drive is generally a grossly expensive process both in terms of money and time, it is better to plan system management as if nothing could be done to a failed drive. I believe I have not used system backups for at least 10 years (thanks to both certain improvements in Windows reliability, but, perhaps, largely due to gained experience and more mature/prudent system management practices), I did burnt my previous laptop (this disaster could probably be also avoided by better maintenance practices). Another important threat to consider includes potential hacker attacks, virus, and ransomware, which may potentially compromise any local files rendering any data virtually damaged/lost. Consequently, I am sticking with partitioned drive.

I generally split the system drive into at least four partitions (until recently, I used place the swap file on a dedicated partition, which is probably unnecessary, particularly in case of an SSD drive):

| Partition         | Anticipated Usage (GB) | Planned Size (GB) |
| ----------------- | ---------------------: | ----------------: |
| System            |                    160 |               200 |
| Portable Programs |                     40 |                50 |
| Data              |                    100 |               200 |
| Buffer            |                      - |   Remaining space |

**Usage Patterns and Recovery Cost Considerations** 

For optimal system management it is important to carefully consider typical usage patterns and potential necessary costs associated with damage recovery. On the two polar ends are the system and use created files.

**System files**

By system files, I mean the files and directories created by Windows installer (such as `C:\Windows`), as well as any additional drivers installed. Additionally, I also include here three major runtime libraries - MS VC++ Redistributable packages, Java, and dotNET. These components are installed once and, except for occasional updates, can be treated for the purpose of potential recovery as mostly unchanged throughout the life cycle of the computer. In case of a damage, these files are straightforwardly recovered even without a fresh (or any) backup system image via the same installation process, with the only associated cost being time required to install them.

**User Created Files**

In contrast, user created files are typically the most precious among all stored files, often far outweighing any setup costs and the costs of the hardware. Usually, there is no efficient means to recover such files without current **and** uncompromised backups.

**Program Files**

Any additionally installed software can be reinstalled the same way, and, in this sense, additional software is close to system files in terms of potential disaster recovery costs. Windows installer creates two system directories to be used for x32 (e.g., "C:\Program Files (x86)") and x64 (e.g., "C:\Program Files") software packages installed system-wide (that is with admin privileges). While using these directories from the point of usage patterns (infrequently updated files) and recovery costs (can be reinstalled from installers without any backups) might make sense, additional software may (and often will) significantly increase the system image size and make it less predictable, complicating drive portioning, backing up, and restoring. At the same time, there is another important factor that affects optimal backing up patterns for different software packages (to be discussed below). For these reasons, the system program files directories should only be used for select installations, while moving the rest on non-system partitions.

**Windows System User Data Directories**

Windows installer also creates another system directory to be used for storing user specific data. These data is potentially quite diverse. First of all, user data consists of two separate components:
- **System-wide User Data:** These data includes the Default (e.g., "C:\Users\Default") user profile used as a template for creation of new Windows user accounts, as well as program settings and components that apply to all users (e.g., "C:\ProgramData"). This component can only be changed with administrative privileges. Since most of the day-to-day work should always be performed under a limited/restricted account without administrative privileges, system-wide user data can be considered as infrequently updated. Importantly, if default user profile (or system-wide system-related user data) is damaged, recovery will likely necessitate the use of backed system image, if available, or clean up system reinstallation otherwise. If system-wide settings associated with a particular non-system application are corrupted, such an application may need to be reinstalled.
- **Individual User Profiles:** 


- **System User Settings:** When a new Windows account is created, the system settings associated with this account are stored within the users directory. These settings can be generally changed with that user's privileges (without administrative privileges). These settings are, perhaps the most important from the point of user's account usability. If corrupted, the user's account will be rendered completely unusable. The simplest recovery root would be re-creation of the user account, assuming this scenario is included as part of the system management strategy from the start. Alternative being partial or full system image restoration, though full system image restoration should be generally reserved for total system failure. If properly planned in advanced, re-creation of the user account might be a better route.
- **Program Settings:** The second major component of the user's data directory includes settings for individual non-system programs, such as office, CAD, or graphics applications. In case of corruption, the simplest recovery option 
- 


For the same reason, I strongly prefer portable software and keep it on a separate partition. While system partition must be imaged for backup purposes, the portable programs partition can be backed up using a simpler file-based tools, including general purpose archives. Portability involves two components: lack of installer (distributed as an archive, possibly self-extracting) and local storage of settings in a settings file within the program directory. For the purpose of program placement on the portable programs partition, I treat the notion of portability more generally. For example, many programs that come with an installer and are not advertised as portable, can be treated as such to some extent (often the installer can be unpacked with a general purpose or specialized unpacker, and the program would work just fine without actual installation). The second component is program configuration. A truly portable program should support saving settings in a file in a user specified location (or at least within the program directory). When the program stores settings in the user application Windows directory, settings/profile portability can be simulated by moving the profile into the app's directory (or, perhaps, to the data partition, following by creating directory junctions in the original location, so that the app could access them transparently; handy batch scripts can also be created / adapted for automatic creation of such junctions and stored together with profile/settings). When settings are stored in the registry, there is no similar straightforward approach. The core settings can be exported as a registry file to be stored within the program directory, possibly, providing the next best thing.



