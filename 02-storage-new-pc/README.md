# Storage Considerations for a New PC

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

The following considerations primarily apply to Windows systems, though they might be applicable to other systems as well. A major advantage of having a single partition is not having to worry about provisioning enough space on individual partitions yet avoiding inefficient drive use due to excessive unused/fragmented free space. Historically, my primary motivation for partitioning the drive was ensuring efficient data integrity workflow and robust recovery in case of system corruption or worse complete failure of the drive. Because data recovery from a failed drive is generally a grossly expensive process both in terms of money and time, it is better to plan system management as if nothing could be done to a failed drive. I believe I have not used system backups for at least 10 years (thanks to both certain improvements in Windows reliability, but, perhaps, largely due to gained experience and more mature/prudent system management practices), I did burnt my previous laptop (this disaster could probably be also avoided by better maintenance practices). Another important threat to consider includes potential hacker attacks, virus, and ransomware, which may potentially compromise any local files rendering any data virtually damaged/lost. Consequently, I am sticking with partitioned drive.

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

By system files, I mean the files and directories created by Windows installer, as well as any additional drivers installed. Additionally, I also include here three major runtime libraries - MS VC++ Redistributable packages, Java, and dotNET. These components are installed once and, except for occasional updates, can be treated for the purpose of potential recovery as mostly unchanged throughout the life cycle of the computer. In case of a damage, these files are straightforwardly recovered even without a fresh (or any) backup system image via the same installation process, with the only associated cost being time required to install them.

**User Created Files**

In contrast, user created files are typically the most precious among all stored files, often far outweighing any setup costs and the costs of the hardware. Usually, there is no efficient means to recover such files without current **and** uncompromised backups.

**Program Files**

Any additionally installed software can be reinstalled the same way, and, in this sense, software is close to system files in terms of potential disaster recovery costs.

**Installed Windows File System Structure Considerations**



For the same reason, I strongly prefer portable software and keep it on a separate partition. While system partition must be imaged for backup purposes, the portable programs partition can be backed up using a simpler file-based tools, including general purpose archives. Portability involves two components: lack of installer (distributed as an archive, possibly self-extracting) and local storage of settings in a settings file within the program directory. For the purpose of program placement on the portable programs partition, I treat the notion of portability more generally. For example, many programs that come with an installer and are not advertised as portable, can be treated as such to some extent (often the installer can be unpacked with a general purpose or specialized unpacker, and the program would work just fine without actual installation). The second component is program configuration. A truly portable program should support saving settings in a file in a user specified location (or at least within the program directory). When the program stores settings in the user application Windows directory, settings/profile portability can be simulated by moving the profile into the app's directory (or, perhaps, to the data partition, following by creating directory junctions in the original location, so that the app could access them transparently; handy batch scripts can also be created / adapted for automatic creation of such junctions and stored together with profile/settings). When settings are stored in the registry, there is no similar straightforward approach. The core settings can be exported as a registry file to be stored within the program directory, possibly, providing the next best thing.



