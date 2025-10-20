<!---
https://chatgpt.com/c/68f3a65b-232c-8329-be89-c05bc8cbf013
-->

# Building and Installing FFCV on Windows

_Self-contained, minimal-prerequisite Windows scripts for bootstrapping reproducible, isolated Python environments with natively built FFCV and Fastxtend, using Micromamba and MSVC._

## 🧭 Summary

This project provides a fully automated Windows build pipeline for the [FFCV](https://github.com/libffcv/ffcv) and [Fastxtend](https://github.com/warner-benjamin/fastxtend) libraries. It reconstructs missing installation logic for native dependencies and configures a clean, reproducible environment using Micromamba and MS Build Tools - without requiring a preinstalled Python setup.

The provided scripts:
- Bootstrap a self-contained, Conda-compatible environment (`Anaconda.bat`);
- Automatically fetch and configure OpenCV, pthreads, and LibJPEG-Turbo;
- Activate the MSVC toolchain for native compilation; and
- Build and install FFCV and Fastxtend directly from PyPI in one step.

The environment is designed for Windows 10+ with ANSI-color-capable terminals (set `NO_COLOR=1` for graceful fallback) and minimal prerequisites (`curl`, `tar`, and MSVC). Its modular structure enables both reproducible automation and transparent debugging, making it a practical foundation for studying or extending Python build-time dependency management.

## 💡 Motivation

While FFCV and Fastxtend might be powerful tools for high-throughput data loading and fastai integration, their Windows installation paths have long been underdocumented and partially broken. The original build process lacks correct setup logic for native dependencies and fails to properly interface with the MSVC toolchain. This project was created to close that gap - providing a transparent, reproducible build system that makes native Windows installations reliable, scriptable, and educational for developers studying Python package compilation and dependency resolution.

➡ **Skip ahead if you just want to build and run.**  
The next section walks you through the one-command setup for a fully functional Windows environment with FFCV and Fastxtend preinstalled, followed by a technical deep dive.

## ⚡ Quick Start

### Prerequisites

- Windows 10+
- [MS Build Tools](https://visualstudio.microsoft.com/visual-cpp-build-tools) installed (C++ workload, see [also](https://stackoverflow.com/a/64262038/17472988))
- `curl` and `tar` on `PATH` (default on modern Win10)
- Internet access

> Tip: set `NOCOLOR=1` to disable ANSI colors if your console doesn’t support them.

### 1. Clone

```cmd
git clone https://github.com/pchemguy/FFCVonWindows.git
cd AIFFCV
```

### 2) Bootstrap + Install (everything)

Run the single entry point.

```cmd
call Anaconda.bat
```

It will:
- verify prerequisites (MSVC, GPU via `nvidia-smi`, curl/tar),    
- set up cache,
- fetch/prepare libraries (OpenCV, pthreads, libjpeg-turbo),
- download Micromamba,
- create the environment,
- and install `ffcv` + `fastxtend`.

> [!WARNING]
> 
> - The Conda environment file included in the project contains some extra components that are not dependencies of FFCV.
> - The environment resolution process is slow and does not output any progress feedback to console.


Success cues include lines like:

```
-[OK]- Micromamba: Completed
-[OK]- Environment "AIFFCV\Anaconda" is created.
Building wheel for ffcv (setup.py) ... done
Successfully installed ffcv-... fastxtend-...
```

### 3) Validate

```cmd
AIFFCV\Anaconda\python - <<PY
import ffcv, fastxtend
print("FFCV + Fastxtend OK")
PY
```

(or just `python` if you’re already in the activated shell).

### Idempotency

Re-running `Anaconda.bat` is safe: environment bootstrapping process will terminated if existing Python executable is found.










## Overview

The [Fast Forward Computer Vision (FFCV)](https://github.com/libffcv/ffcv) library addresses one of the most common bottlenecks in large-scale AI model training - high-latency data loading from disk to RAM when working with millions of small image files. Its companion project, [Fastxtend](https://github.com/warner-benjamin/fastxtend/), extends FFCV integration to the [fastai](https://github.com/fastai/fastai) ecosystem.

Although both projects nominally support Windows, neither provides functioning Windows installation instructions. FFCV’s setup script (`setup.py`) fails to locate and configure required native dependencies. This repository documents and automates a working Windows build and installation pipeline for FFCV and Fastxtend using native MS Build Tools and a standalone Micromamba manager - without modifying the upstream sources.




## Motivation

FFCV is distributed on PyPI as a source-only package requiring native compilation. On Windows, this requirement introduces challenges not typically encountered on Linux:

- Missing or misconfigured build toolchains (MSVC / MS Build Tools)
- Incorrect dependency paths (`.h`, `.lib`, `.dll`)
- Unreliable setup logic in the FFCV `setup.py` build process

Because I prefer developing on Windows and wanted to evaluate FFCV and Fastxtend in a reproducible setting, I designed a self-contained bootstrap process that:

1. Automatically installs and verifies external libraries (OpenCV, LibJPEG-Turbo, pthreads).
2. Configures compiler and linker variables dynamically to ensure a successful `pip install ffcv` build.
3. Creates an isolated Python environment using Micromamba (no base Python required, see also [this note](https://github.com/pchemguy/Field-Notes/blob/main/03-python-env-windows/README.md)). 

## Understanding the Build Problem

The FFCV installation failures fall into three categories:

1. **{LIBRARY} not found** - library's binaries are not on the `PATH`.
2. **MSVC compiler missing** - `pip` and `setuptools` often fail to detect MS Build Tools even when properly installed.
3. **Linker errors** — Missing or misreferenced `.lib` files prevent external function resolution.

FFCV’s build system relies on the setup script `setup.py` to generate compiler and linker flags for `setuptools`.  
On Linux, standard system directories make this straightforward.  
On Windows, the process is fragile due to the lack of a consistent directory structure for library and header files.

## Dependency Resolution on Windows

### Build-Time Requirements

Successful installation of FFCV requires four critical dependency types:

| Stage | Requirement       | Description                                     |
| ----- | ----------------- | ----------------------------------------------- |
| 1     | `*.h` headers     | Compiler input (location of C/C++ headers)      |
| 2     | `*.lib` libraries | Linker import libraries (location)              |
| 3     | `*.lib` filenames | Explicitly listed linker targets                |
| 4     | `*.dll` binaries  | Runtime dependencies (not needed at build time) |

Items (1)-(3) must be known before compilation.  
Item (4) - runtime DLLs - must be discoverable on the `PATH` once FFCV is installed.

### Key Environment Variables

These are the native Windows environment variables that influence the build process:

|Variable|Purpose|
|---|---|
|`INCLUDE`|Directories containing header (`*.h`) files|
|`LIB`|Directories containing import (`*.lib`) files|
|`LINK`|Additional linker arguments, including `.lib` filenames|
|`PATH`|Directories containing runtime DLLs|

By predefining these variables before `pip install`, the build process can succeed without editing FFCV’s `setup.py`.

## Why Linux Builds Work (and Windows Doesn’t)

Linux places shared libraries in standard system paths such as `/usr/include` and `/usr/lib`.  
Windows does not - each project or installer chooses its own directory structure.  
Conda partially standardizes the directory structure relative to environment top directory via the `Library/` hierarchy:

```
Library/bin/
Library/include/
Library/lib/
```

However, FFCV is not designed to use library variants provided by the Conda ecosystem, so setup logic (`pkgconfig_windows`) does not utilize these paths and instead produces meaningless values. To resolve this issue, the provided scripts set all necessary paths before bootstrapping environment.

## Automated Environment Layout

This project populates the following reproducible directory structure:

```
AIPY/
├─ Anaconda/               ← Micromamba-created Python environment
│   ├─ python.exe
│   └─ Library/...
├─ pthreads/
│   ├─ dll/x64/pthreadVC2.dll
│   ├─ include/pthread.h
│   └─ lib/x64/pthreadVC2.lib
├─ opencv/
│   └─ build/x64/vc15/...
└─ libjpeg-turbo/
```

Environment activation scripts add each library’s include, lib, and dll paths in a safe, layered order:

1. Library-specific paths (`pthreads`, `opencv`)    
2. Conda environment paths (`Library/*`)
3. System paths (fallback)

This hierarchy reduces the risks of name collisions between Conda-provided and system libraries.

## FFCV `setup.py` Analysis

FFCV’s Windows configuration logic resides in `pkgconfig_windows(package, kw)`. Its intended purpose is to discover headers and libraries automatically, but as of `ffcv==1.0.2`, it produces random and invalid paths.

Adding temporary print statements inside this function, right before `return kw`, such as:

```python
print("==================================================================")
print(package)
print(kw)
print("==================================================================")
```

reveals that the generated include and library directories are nonsensical (consistent with code logic). Thus, rather than modifying upstream code, this project injects correct configuration values via environment variables.

## Library Settings

FFCV requires three native dependencies:

| Library            | Version                | Source           | Integration Strategy |
| ------------------ | ---------------------- | ---------------- | -------------------- |
| **OpenCV**         | 4.6.0 VC15             | Official build   | External install     |
| **LibJPEG-Turbo**  | Not restricted         | Conda package    | Use Conda version    |
| **pthreads-win32** | 2.9.1 (latest release) | Sourceware (FTP) | External install     |

### Configuration Summary

| Dependency        | Path Additions                                                                         | LIB Files             |
| ----------------- | -------------------------------------------------------------------------------------- | --------------------- |
| **pthreads**      | `dll/x64` → PATH<br>`include` → INCLUDE<br>`lib/x64` → LIB                             | `pthreadVC2.lib`      |
| **OpenCV**        | `build/x64/vc15/bin` → PATH<br>`build/include` → INCLUDE<br>`build/x64/vc15/lib` → LIB | `opencv_world460.lib` |
| **LibJPEG-Turbo** | `Library/bin` → PATH<br>`Library/include` → INCLUDE<br>`Library/lib` → LIB             | `turbojpeg.lib`       |

All paths are automatically configured during environment activation via the `conda_far.bat` and related scripts.

## Building from Source

Once the environment is fully initialized: The `pip` process will inherit pre-configured `INCLUDE`, `LIB`, and `LINK` values, allowing `setuptools` to compile FFCV successfully with MSVC.

## Sample Project Structure

This repository includes a modular set of batch scripts designed for full reproducibility:

| Script                         | Role                                                   |
| ------------------------------ | ------------------------------------------------------ |
| **Anaconda.bat**               | Main entry point - bootstraps and verifies environment |
| **libs.bat**                   | Downloads and extracts library archives                |
| **pthreads/activate.bat**      | Sets pthreads-related variables                        |
| **opencv/activate.bat**        | Sets OpenCV-related variables                          |
| **libjpeg-turbo/activate.bat** | Sets LibJPEG-Turbo variables                           |
| **conda_far.bat**              | Activates MS Build Tools and library environment       |

Each module performs one explicit task and cleans up its variables before returning.

## References

- [FFCV GitHub Repository](https://github.com/libffcv/ffcv)
- [Fastxtend GitHub Repository](https://github.com/warner-benjamin/fastxtend/)
- [Microsoft Visual C++ Build Tools](https://visualstudio.microsoft.com/visual-cpp-build-tools)
- [SO: How to install MS Build Tools for pip](https://stackoverflow.com/a/64262038/17472988)
- [Field Notes: Bootstrapping Python Environments on Windows](https://github.com/pchemguy/Field-Notes/blob/main/03-python-env-windows/README.md)
- [Field Notes: Python pip & MSVC Detection Issues](https://github.com/pchemguy/Field-Notes/blob/main/05-python-pip-msvc/README.md)


## Troubleshooting

- Missing compiler - SO install MSVC
- Missing package - paths
- Missing compiler - SO configure MSVC (DISTUTILS SDK)
- DLL loading error
