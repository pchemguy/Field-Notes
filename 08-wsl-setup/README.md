<!-- https://gemini.google.com/app/cf4f2fb394b7efe5 -->

# Setting up WSL for AI Development

While native Linux remains the gold standard for machine learning workflows due to Windows' architectural overhead, transitioning to a full dual-boot system isn't always immediate. A robust compromise is WSL 2 (Windows Subsystem for Linux). It resolves key performance bottlenecks by running a lightweight Linux kernel alongside Windows, minimizing the virtualization penalty compared to traditional VMs.

The default WSL installation process is often a "black box", burying the virtual disk deep within the Windows system drive. For a data-intensive AI setup, we need granular control over storage locations.

This setup proceeds in two distinct stages: **Engine Installation** and **Distro Import**.

## Stage 1: The WSL Engine

The first step installs the hypervisor and Linux kernel without registering a default distribution, avoiding creation of an unwanted Ubuntu instance on the Windows system drive.

```batch
wsl --install --no-distribution
```

This command installs the [latest release](https://github.com/microsoft/WSL) of the core WSL components.

* **Verification:** After a mandatory reboot, verify the installation by checking `%ProgramFiles%\WSL`.
* **Key Artifacts:** You should see `wsl.exe`, `wslservice.exe`, and `system.vhd`.

## Stage 2: Custom Distro Import

The standard `wsl --install` command offers no control over where the Linux filesystem (`ext4.vhdx`) is stored. To place the system image on a dedicated partition (e.g., `D:\WSL_System`), we must manually import the distribution.

### The File Formats

Crucially, the `install` and `import` commands require different source file formats:

1. **Standard Installer (`.wsl`/`.appx`):** WSL image used by the automatic installer. Wraps the OS in Windows store metadata and triggers an automatic setup wizard.
2. **RootFS Tarball (`.rootfs.tar.gz`):** A raw archive of the OS filesystem. This is required for manual importing.

* **Download Source:** [Ubuntu Cloud Images (WSL Releases)](https://cloud-images.ubuntu.com/wsl/releases/24.04/current/)
* **Target File:** `ubuntu-noble-wsl-amd64-24.04lts.rootfs.tar.gz`

### The Import Command

Instead of the default installation:

```batch
# AVOID: Installs to default C: location
wsl --install --from-file ubuntu-24.04.3-wsl-amd64.wsl
```

We use the import command to define a custom location:

```batch
# RECOMMENDED: Creates the system disk on the D: drive
wsl --import "UbuntuLTS" "D:\WSL_System\UbuntuLTS" "ubuntu-noble-wsl-amd64-24.04lts.rootfs.tar.gz" --version 2
```

## Stage 3: Data Strategy

While the OS image (`ext4.vhdx`) now resides on a dedicated NTFS partition, placing heavy training data inside a virtual disk file is still suboptimal.

**Best Practice:**

1. **System:** Keep the OS image small (on the NTFS partition).
2. **Data:** Format a dedicated physical drive as ext4.
3. **Mount:** Pass the raw physical drive directly to WSL using `wsl --mount`. This approach bypasses NTFS translation entirely for native Linux I/O performance.
