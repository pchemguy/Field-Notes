<!-- https://gemini.google.com/app/cf4f2fb394b7efe5 -->

# Setting up WSL for AI Development

While native Linux remains the gold standard for machine learning workflows due to Windows' architectural overhead, transitioning to a full dual-boot system isn't always immediate. A robust compromise is WSL 2 (Windows Subsystem for Linux). It resolves key performance bottlenecks by running a lightweight Linux kernel alongside Windows, minimizing the virtualization penalty compared to traditional VMs.

The default WSL installation process is often a "black box", burying the virtual disk deep within the Windows system drive. For a data-intensive AI setup, we need granular control over storage locations.

This setup proceeds in two distinct stages: **Engine Installation** and **Distro Import**.

## Stage 1: WSL Engine

The first step installs the hypervisor and Linux kernel without registering a default distribution, avoiding creation of an unwanted Ubuntu instance on the Windows system drive.

```batch
wsl --install --no-distribution
```

This command installs the [latest release](https://github.com/microsoft/WSL) of the core WSL components.

* **Verification:** After a mandatory reboot, verify the installation by checking `%ProgramFiles%\WSL`.
* **Key Artifacts:** You should see `wsl.exe`, `wslservice.exe`, and `system.vhd`.

## Stage 2: Distro Import

The standard `wsl --install` command offers no control over where the Linux filesystem (`ext4.vhdx`) is stored. To place the system image on a dedicated partition (e.g., `D:\WSL_System`), we must manually import the distribution.

### File Formats

Crucially, the `install` and `import` commands require different source file formats:

1. **Standard Installer (`.wsl`/`.appx`):** WSL image used by the automatic installer. Wraps the OS in Windows store metadata and triggers an automatic setup wizard.
2. **RootFS Tarball (`.rootfs.tar.gz`):** A raw archive of the OS filesystem. This is required for manual importing.

### Scriptable (via --install/export/import)

#### Default Install

**Online:**

```batch
wsl --install Ubuntu-24.04 --name UbuntuLTS
```

**Offline**:
- WSL Image Release from https://releases.ubuntu.com/noble/
- File: https://releases.ubuntu.com/noble/ubuntu-24.04.3-wsl-amd64.wsl

```batch
wsl --install --name UbuntuLTS --from-file ubuntu-24.04.3-wsl-amd64.wsl
```

#### Move

`wsl --export UbuntuLTS D:\backup\ubuntults.tar`
`wsl --unregister UbuntuLTS`
`wsl --import UbuntuLTS D:\WSL\UbuntuLTS D:\backup\ubuntults.tar`

### Direct (via --import)

* **Download Source:** [Ubuntu Cloud Images (WSL Releases)](https://cloud-images.ubuntu.com/wsl/releases/24.04/current/)
* **Target File:** `ubuntu-noble-wsl-amd64-24.04lts.rootfs.tar.gz`
* **Import:**

```batch
wsl --import "UbuntuLTS" "D:\WSL_System\UbuntuLTS" "ubuntu-noble-wsl-amd64-24.04lts.rootfs.tar.gz" --version 2
```

## Stage 3: Launch/Terminate the Distro

**Start:**

```batch
wsl -d UbuntuLTS
```

**Terminate:**

```
wsl --terminate UbuntuLTS
```

## Stage 4: Configure the User

**Bash:**

```bash
useradd -m -G sudo -s /bin/bash yourusername
passwd yourusername
```

**Default User (for example, via PowerShell from Windows or inside Linux):**
- **PowerShell-side approach**

```PowerShell
$config = "[user]`ndefault=yourusername"
$config | Out-File -FilePath "\\wsl$\UbuntuLTS\etc\wsl.conf" -Encoding ascii
```

- **Linux-side approach**

 ```
 echo -e "[user]\ndefault=myuser" > /etc/wsl.conf
 ```

## Stage 5: Data Storage

### Use Physical Ext4 Drive

**General scheme (PowerShell example):**
1. `GET-CimInstance -query "SELECT * from Win32_DiskDrive"`: Identify your physical data drive.
2. `wsl --mount \\.\PHYSICALDRIVE1 --partition 1 --type ext4`: Adjust `PHYSICALDRIVE` number and partition number as needed.

> [!NOTE]
> 
> `wsl --mount` does not persist after a reboot.

**Persistence inside Linux:**

```
mkdir -p /home/myuser/projects
# Add to /etc/fstab for internal persistence
/mnt/wsl/PHYSICALDRIVE1p1 /home/myuser/projects none bind 0 0
```

### Use Portable VHDX Ext4 Drive

#### 1. Create New Image (DiskPart or PowerShell)

**DiskPart:**

```diskpart
create vdisk file="D:\WSL_Data\portable_ext4wsl.vhdx" maximum=102400 type=fixed
```

**PowerShell:**

```PowerShell
# Create a 100GB fixed-size disk (Fixed is faster than Dynamic)
New-VHD -Path "D:\WSL_Data\portable_ext4wsl.vhdx" -SizeBytes 100GB -Fixed
```

#### 3. Mount Raw VHDX

```batch
wsl --mount "D:\WSL_Data\portable_ext4wsl.vhdx" --vhd --bare
```

#### 3. Format VHDX inside Linux (once)

```bash
lsblk
# Identify the device (e.g., /dev/sdd).
# Since it's a raw VHDX, it likely won't have partitions yet, or just be the raw block device.
# Format the whole disk as ext4
sudo mkfs.ext4 /dev/sdd
```

#### 4. Unmount VHDX

```batch
wsl --unmount "D:\WSL_Data\portable_ext4wsl.vhdx"
```

#### 5. Mount Formatted VHDX

```batch
:: Note
::   `--name DataDrive` mounts drive at `/mnt/wsl/DataDrive`.
::   If `--name DataDrive`, VHDX filename should be used as mount point name.
wsl --mount "D:\WSL_Data\portable_ext4wsl.vhdx" --vhd --type ext4 --name DataDrive
```

## Import/Export System VM Image

`wsl --export UbuntuLTS D:\backup\ubuntults.tar`
`wsl --unregister UbuntuLTS`
`wsl --import UbuntuLTS D:\WSL\UbuntuLTS D:\backup\ubuntults.tar`

## Data Strategy

While the OS image (`ext4.vhdx`) now resides on a dedicated NTFS partition, placing heavy training data inside a virtual disk file is still suboptimal.

**Best Practice:**

1. **System:** Keep the OS image small (on the NTFS partition).
2. **Data:** Format a dedicated physical drive as ext4. Pass the raw physical drive directly to WSL using `wsl --mount`. This approach bypasses NTFS translation entirely for native Linux I/O performance.
3. **Portable:** Portable software installs may potentially go to a separate VHDX-EXT4. Extra penalty for reading VHDX from NTFS before hitting Ext4 for software (as opposed to data) should be inconsequential. For data, using a VHDX instead of a physical drive may or may not be problematic. If data goes into a VHDX, NEVER use the system VHDX for this purpose. ALWAYS have a physically separate DATA.VHDX image file.

## Explorer Active VM FS

```
cd \\WSL$
```
