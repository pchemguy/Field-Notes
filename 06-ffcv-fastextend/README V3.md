# **Building and Installing FFCV on Windows**

_Self-contained Windows scripts for bootstrapping reproducible, isolated Python environments with natively built FFCV and Fastxtend - using Micromamba and MSVC._

## Summary

This project provides a fully automated Windows build pipeline for the [FFCV](https://github.com/libffcv/ffcv) and [Fastxtend](https://github.com/warner-benjamin/fastxtend) libraries. It reconstructs missing installation logic for native dependencies and configures a clean, reproducible environment using Micromamba and MS Build Tools - all without requiring a preinstalled Python setup.

The provided scripts:  
- Bootstrap a self-contained, Conda-compatible environment (`Anaconda.bat`);
- Automatically fetch and prepare OpenCV, pthreads, and LibJPEG-Turbo;
- Intelligently detect and activate the MSVC toolchain (`msbuild.bat`); and
- Build and install **FFCV** and **Fastxtend** directly from PyPI without any developer's manual intervention.

The environment targets Windows 10+ with ANSI-color-capable terminals (set `NOCOLOR=1` for graceful fallback). Its modular design emphasizes transparency, reproducibility, and debuggability, making it both a practical solution and a learning tool for developers exploring Python’s native build systems on Windows.

## 💡 Motivation

While FFCV and Fastxtend are potentially powerful tools for high-throughput data loading and fastai integration, their Windows installation workflow has long been underdocumented and partially broken. The original build process lacks proper handling of native dependencies and fails to interface cleanly with the MSVC toolchain.

This project fills that gap - providing a transparent, script-driven build system that makes native Windows installations reproducible, educational, and reliable for both experimentation and production use.

## ⚡ Quick Start

### 🧭 Prerequisites

1. **Windows 10/11:** Modern `cmd.exe` with ANSI color support is recommended.
2. **MS Build Tools:** The C++ workload is required. You can install this toolchain with the [Visual Studio Build Tools](https://visualstudio.microsoft.com/visual-cpp-build-tools) (select "Desktop development with C++").
3. **System Tools:** `curl.exe` and `tar.exe` must be in your `PATH`. (These tools are included by default in modern Windows 10/11).
4. **Internet Access:** Required to download libraries and packages.

> 💡 **Tip:** Set `NOCOLOR=1` (e.g., `set NOCOLOR=1`) to disable ANSI colors if your console doesn't support them.

### 🚀 Installation

**1. Clone the Repository:**

```
git clone https://github.com/pchemguy/FFCVonWindows.git
cd AIFFCV
```

**2. Run the Bootstrapper:**

From a clean cmd.exe prompt (i.e., without any other Python or Conda environment already activated), run the main entry point:

```
> Anaconda.bat
```

This single script will:  
- Verify all prerequisites (including MSVC, GPU, `curl`, `tar`).
- Set up a local cache directory.
- Fetch and extract OpenCV, pthreads, and LibJPEG-Turbo.
- Download Micromamba.
- Create the full Conda environment from the included YAML files.
- Install `ffcv` and `fastxtend`, compiling them with the activated MSVC toolchain.
- Verify the installation.

### ⚙️ MSVC Detection

The `Anaconda.bat` script (via `msbuild.bat`) will automatically try to find your MS Build Tools installation. It checks standard install paths, environment variables (`%ProgramFiles%`, `BUILDTOOLS`, etc.), and `PATH`.

If the script fails at the "MS Build Tools Check" step (see screenshot below), it means it couldn't find your installation.

**To fix this problem:** You can "help" the script by setting the `BUILDTOOLS` environment variable to point to your installation directory _before_ running `Anaconda.bat`. This is the directory containing the `VC`, `Common7`, etc. folders.

```
:: Example:
set "BUILDTOOLS=C:\Program Files\Microsoft Visual Studio\2022\BuildTools"
> Anaconda.bat
```

### 🎨 Color Convention

Scripts use consistent, minimal color-coded labels (set `NOCOLOR=1` for plain text):

| **Label**     | **Meaning**                                                                        |
| ------------- | ---------------------------------------------------------------------------------- |
| **`[WARN]`**  | Major stage banner, beginning of a subtask, or warning (e.g. MS Build Tools check) |
| **`[INFO]`**  | Progress and diagnostic output                                                     |
| **`[-OK-]`**  | Successful task or step completion                                                 |
| **`[ERROR]`** | Critical failure causing termination                                               |

At the end of a successful installation, you should see an `[OK]` banner as shown below.

**MS Build Tools Check - Failed**

![](./AIFFCV/Screenshots/MSBuild_failed.jpg)

**MS Build Tools Check - Passed**

![](./AIFFCV/Screenshots/MSBuild_passed.jpg)

**Successful Completion**

![](./AIFFCV/Screenshots/completion.jpg)

## 🗂️ Project Structure

This repository is designed as a self-contained build system. Here are the key components and their roles:

| **File / Directory**         | **Role**                                                                                                                                                                                                                                  |
| ---------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **`Anaconda.bat`**           | **Main Entry Point.** Orchestrates the entire bootstrap, download, and installation process. This is the only script you need to run.                                                                                                     |
| `Anaconda.yml`               | The **main Conda environment** file. Defines all Python packages (PyTorch, fastai, etc.) for the project.                                                                                                                                 |
| `Anaconda_bootstrap.yml`     | A **minimal environment** file used _only_ by `Anaconda.bat` to set up a tiny base with Micromamba and `uv` before creating the full environment.                                                                                         |
| **`conda_far.bat`**          | **Environment Activator.** This script _activates_ the fully-configured environment, ensuring MSVC and all library paths are set correctly. It is used by `Anaconda.bat` and can be run manually to enter an interactive activated shell. |
| **`msbuild.bat`**            | **MSVC Detector.** A robust helper script that finds and activates the MS Build Tools environment. Called by other scripts.                                                                                                               |
| **`libs.bat`**               | **Library Manager.** A multi-purpose script for managing native dependencies. `Anaconda.bat` calls it to download, extract, and "install" (copy) DLLs. `conda_far.bat` calls it to activate library paths.                                |
| `pthreads/activate.bat`      | Sets the `INCLUDE`, `LIB`, `LINK`, and `PATH` variables for the pthreads library.                                                                                                                                                         |
| `opencv/activate.bat`        | Sets the `INCLUDE`, `LIB`, `LINK`, and `PATH` variables for the OpenCV library.                                                                                                                                                           |
| `libjpeg-turbo/activate.bat` | Sets the `INCLUDE`, `LIB`, `LINK`, and `PATH` variables for the Conda-provided LibJPEG-Turbo library.                                                                                                                                     |

## 🔬 Deep Dive

### The General Problem: Building Native Python Packages on Windows

When `pip install` builds a package from source, it invokes the MSVC toolchain (compiler and linker). This process fails if the toolchain cannot find the C/C++ header files (`.h`), import libraries (`.lib`), and linker targets for the package's native dependencies.

Unlike Linux, which uses standard paths like `/usr/include`, Windows paths are fragmented. To find necessary files, the MSVC toolchain relies on four key environment variables:

|**Variable**|**Purpose**|
|---|---|
|`INCLUDE`|**Compiler:** Directories containing header files (`*.h`).|
|`LIB`|**Linker:** Directories containing import libraries (`*.lib`).|
|`LINK`|**Linker:** Additional arguments, including the _specific names_ of the `*.lib` files to link (e.g., `pthreadVC2.lib`).|
|`PATH`|**Runtime:** Directories containing dynamic-link libraries (`*.dll`).|

If these variables are pre-set with the correct paths _before_ `pip install` is run, the build should succeed even if the package's `setup.py` logic is broken.

### The MSVC Detection Trap: `cl.exe` is on PATH, but `pip` Fails

A common and deeply frustrating error on Windows is pip failing with:

```
Microsoft Visual C++ 14.0 or greater is required.
```

This is especially confusing when you have _already_ activated the MSVC environment (e.g., by running `vcvarsall.bat`) and can successfully run `cl.exe` from your terminal.

The problem is that `setuptools` (specifically the `setuptools\_distutils\compilers\C\msvc.py` module) ignores your `PATH`. Instead of checking for `cl.exe`, its `_get_vc_env()` function attempts to "find" MSVC using its own limited logic:

1. It calls `_find_vc2017()`, which looks for `vswhere.exe` in a **hardcoded** `%ProgramFiles(x86)%` path.
2. It calls `_find_vc2015()`, which checks a **specific registry key** (`HKLM\Software\Microsoft\VisualStudio\SxS\VC7`).

If you have MSVC installed in a custom location, are using a portable version, or have simply activated the environment via `vcvarsall.bat` _without_ it being in the default path/registry, these checks will fail. `setuptools` will incorrectly conclude that MSVC is not installed and raise the error, even though it is perfectly available in your shell.

#### The Solution: `DISTUTILS_USE_SDK=1`

The `setuptools` code provides an escape hatch. The _very first thing_ the `_get_vc_env()` function does is check for an environment variable:

```python
def _get_vc_env(plat_spec):
    if os.getenv("DISTUTILS_USE_SDK"):
        return {key.lower(): value for key, value in os.environ.items()}
    
    # ... rest of the detection logic ...
```

If `DISTUTILS_USE_SDK=1` is set, `setuptools` skips its entire limited detection logic and simply trusts the environment variables (`INCLUDE`, `LIB`, `LINK`, `PATH`) that are already active in the shell.

This is precisely why `conda_far.bat` (which is called by the main `Anaconda.bat` bootstrapper) sets:

```
set "DISTUTILS_USE_SDK=1"
```

This single line forces `pip` and `setuptools` to respect the environment that `msbuild.bat` has prepared, making the native compilation robust and reliable.

### The FFCV-Specific Problem

FFCV’s `setup.py` contains a function, `pkgconfig_windows()`, intended to auto-discover dependencies. However, this logic is non-functional and returns nonsensical paths. Rather than patching FFCV's source code, this project bypasses the problem by pre-populating the environment variables (`INCLUDE`, `LIB`, `LINK`) with the _correct_ values _before_ `pip` is ever called.

### The Solution: A Scripted Build Pipeline

This repository automates the entire setup:  
1. **`Anaconda.bat`** runs `msbuild.bat` to detect and activate the MSVC toolchain, setting the base `INCLUDE` and `LIB` paths.
2. It then calls `conda_far.bat` (in `/preactivate` mode) and `libs.bat` (in `/activate` mode), which in turn call the individual `*/activate.bat` scripts.
3. These scripts _prepend_ the correct paths for **pthreads**, **OpenCV**, and **LibJPEG-Turbo** to the `INCLUDE`, `LIB`, `LINK`, and `PATH` variables.
4. Finally, `Anaconda.bat` calls Micromamba to bootstrap a minimal Conda environment and then Mamba, which imports the full environment specification leading to  `pip install ffcv fastxtend` at the very end, which inherits this preconfigured environment, allowing the build to succeed without modification.
It is important to highlight that one of the dependencies, is part of the same environment file as `FFCV`. This approach works, because Conda/Mamba managers install Conda packages first before invoking `pip`/`uv`.

### Dependency Resolution

This project uses a mix of externally downloaded libraries and one Conda-provided library. This hybrid approach was chosen to match FFCV's requirements while minimizing conflicts.

| **Library**        | **Version**  | **Source**              | **Integration**                |
| ------------------ | ------------ | ----------------------- | ------------------------------ |
| **OpenCV**         | 4.6.0 (VC15) | Official GitHub Release | External (`libs.bat` download) |
| **pthreads-win32** | 2.9.1        | Sourceware FTP          | External (`libs.bat` download) |
| **LibJPEG-Turbo**  | (from Conda) | Conda (`Anaconda.yml`)  | **Internal (Conda-provided)**  |

The `activate.bat` scripts configure the environment as follows:

|               | **pthreads**       | **OpenCV**                  | **LibJPEG-Turbo**          |
| ------------- | ------------------ | --------------------------- | -------------------------- |
| **`PATH`**    | `pthreads\dll\x64` | `opencv\build\x64\vc15\bin` | `Anaconda\Library\bin`     |
| **`INCLUDE`** | `pthreads\include` | `opencv\build\include`      | `Anaconda\Library\include` |
| **`LIB`**     | `pthreads\lib\x64` | `opencv\build\x64\vc15\lib` | `Anaconda\Library\lib`     |
| **`LINK`**    | `pthreadVC2.lib`   | `opencv_world460.lib`       | `turbojpeg.lib`            |

### Build-Time vs. Runtime (DLLs)

Setting the variables above is sufficient for the _build_ to complete. However, when you `import ffcv` in Python, the Windows OS needs to find the _runtime_ DLLs (e.g., `pthreadVC2.dll`, `opencv_world460.dll`).

While our `conda_far.bat` adds these to the `PATH` for the _current shell_, this is not a permanent solution. To make the environment self-contained, `Anaconda.bat` runs a final step:


```
call :COPY_DLLS
(which runs)
call "%~dp0libs.bat" /install
```

This command copies the required runtime DLLs from their staging directories (`pthreads/dll/x64`, `opencv/build/x64/vc15/bin`) directly into the `Anaconda\Library\bin` folder. Since the Conda environment _always_ adds `Library\bin` to its `PATH` upon activation, this ensures that FFCV and its dependencies can be imported successfully in any new shell _after_ just running `conda activate`.

## 📚 References

- [FFCV GitHub Repository](https://github.com/libffcv/ffcv)
- [Fastxtend GitHub Repository](https://github.com/warner-benjamin/fastxtend)
- [Microsoft Visual C++ Build Tools](https://visualstudio.microsoft.com/visual-cpp-build-tools)
- [SO: Installing MS Build Tools for pip](https://stackoverflow.com/a/64262038/17472988)
- [Field Notes: Bootstrapping Python Environments on Windows](https://github.com/pchemguy/Field-Notes/blob/main/03-python-env-windows/README.md)
- [Field Notes: Python pip & MSVC Detection Issues](https://github.com/pchemguy/Field-Notes/blob/main/05-python-pip-msvc/README.md)
