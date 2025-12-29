# Setting up WSL

AI finally managed to persuade me that attempting any serious AI training on a pure Windows machine may not be worth it as Windows has performance-related architectural limitations on multiple levels. At the same time, I am not ready to go all the way Linux (though I provisioned a second system drive for potentially dually bootable Windows/Linux arrangement in the future). According to AI, WSL2 on Windows 11 supposedly should largely resolve key Windows issues, minimizing performance penalties, so I decided to stick with this configuration for now before having a dedicated Linux system.

Windows Subsystem for Linux ([official WSL docs](https://learn.microsoft.com/windows/wsl)) enables running a virtual Linux machine with minimalistic performance penalty. The default installation workflow, while appears to be relatively simple, is also largely a blackboxed. At the same time, a more advanced installation strategy does offer a more exposed alternative.

The setup process proceeds in two stages. The first stage

```
wsl --install --no-distribution
```

downloads and installs the [latest release](https://github.com/microsoft/WSL) of the core WSL setup (offline installation option is also [available](https://learn.microsoft.com/windows/wsl/install#offline-install)). This process should create a directory `%ProgramFiles%/WSL` that should contain `wsl.exe`, `wslservice.exe`, and `system.vhd` among other files.

The second stage involves installing the target Linux distribution(s). WSL supports a fully automatic download/installation process from a library of provided distros given their names. A major limitation of the the fully automatic installation is that it does not provide a means to control where the actual Linux files are placed. What the installation process does, it creates a virtual drive image file `ext4.vhdx` holding the installed virtual Linux system. The automatic installation process buries this image file somewhere inside the Windows user account, which is suboptimal. A better approach would be placing this image on a separate NTFS partion (or even drive). In order to do that, the distro installation process should use an alternative `import` command. Now the 'install' and `import` commands expect slightly different distributions. For example, for `Ubuntu 24.04 LTS`, the `install` command expects a WSL image `*.wsl` available from [here](https://releases.ubuntu.com/noble/), while the `import` command expects a root fs tarball `*.rootfs.tar.gz` available from [here](https://cloud-images.ubuntu.com/wsl/releases/24.04/current/). According,

```
wsl --install --from-file ubuntu-24.04.3-wsl-amd64.wsl
```

installs the distro into default location within the user account, while

```
wsl --import "UbuntuLTS" "D:\WSL_System\UbuntuLTS" "ubuntu-noble-wsl-amd64-24.04lts.rootfs.tar.gz" --version 2
```

creates the image file in the specified location.

This image file contains the operating system. While user data files used by Linux could also go inside this image, a better approach is to place data files on a dedicated ext4-formatted drive mounted via `wsl --mount` command.
