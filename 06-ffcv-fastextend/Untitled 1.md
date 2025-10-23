<!---
https://chatgpt.com/c/68f3a65b-232c-8329-be89-c05bc8cbf013
https://gemini.google.com/app/4ee32a52d7111ccf
https://gemini.google.com/app/f03c2f1ac2d20a92
https://gemini.google.com/app/9eca4ff0bd404da3
https://gemini.google.com/app/dd501bda3a1d042f
-->

# **Building and Installing FFCV on Windows**

_Self-contained Windows scripts for bootstrapping reproducible, isolated Python environments with natively built FFCV and Fastxtend - using Micromamba and MSVC._

## Summary

This project provides a fully automated Windows build pipeline for the [FFCV](https://github.com/libffcv/ffcv) and [Fastxtend](https://github.com/warner-benjamin/fastxtend) libraries. It reconstructs missing installation logic for native dependencies and configures a clean, reproducible environment using Micromamba and MS Build Tools - all without requiring a preinstalled Python setup.

The provided scripts:  
- Bootstrap a self-contained Conda-compatible environment (`Anaconda.bat`);
- Automatically fetch and configure OpenCV, pthreads, and LibJPEG-Turbo;
- Activate the MSVC toolchain for native compilation; and
- Build and install **FFCV** and **Fastxtend** directly from PyPI in one step.

The environment targets Windows 10+ with ANSI-color-capable terminals (set `NOCOLOR=1` for graceful fallback) and minimal prerequisites (`curl`, `tar`, and MSVC).  
Its modular design emphasizes transparency, reproducibility, and debuggability, making it both a practical solution and, hopefully, a learning tool for developers exploring Python’s native build systems.

## 💡 Motivation

While FFCV and Fastxtend are potentially powerful tools for high-throughput data loading and fastai integration, their Windows installation workflow has long been underdocumented and partially broken. The original build process lacks proper handling of native dependencies and fails to interface cleanly with the MSVC toolchain.

This project fills that gap - providing a transparent, script-driven build system that makes native Windows installations reproducible, educational, and reliable for both experimentation and production use.

## ⚡ Quick Start

### 🧭 Prerequisites

- Windows 10+
- [**MS Build Tools**](https://visualstudio.microsoft.com/visual-cpp-build-tools) (C++ workload; see also [this SO answer](https://stackoverflow.com/a/64262038/17472988))
- `curl` and `tar` in `PATH` (default on modern Windows 10)
- Internet access

> 💡 Tip: Set `NOCOLOR=1` to disable ANSI colors if your console doesn’t support them.

### 🚀 Prepare

```cmd
git clone https://github.com/pchemguy/FFCVonWindows.git
cd AIFFCV
```

Make sure MS Build Tools is discoverable from the shell copy you will use for subsequent stage. For example, add the directory containing `vcvars*.bat` scripts to the path or set `BUILDTOOLS` variable to the directory containing `VC`, `VB`, `Common7`, etc. directories, such as `C:\Program Files\Microsoft Visual Studio\2022\BuildTools`

### ⚙️ Bootstrap and Install

Run the single entry point:

```cmd
>Anaconda.bat
```

This will:  
- Verify prerequisites (MSVC, GPU via `nvidia-smi`, `curl`, `tar`);
- Set up cache;
- Fetch and prepare OpenCV, pthreads, LibJPEG-Turbo;
- Download Micromamba;
- Create the Conda environment; and
- Install `ffcv` and `fastxtend`.

> [!WARNING]  
> The included Conda environment file also contains a few libraries not required by FFCV.

### 🎨 Color Convention

Modern Windows 10+ `cmd.exe` supports ANSI escape sequences for colored output. Scripts in this project use consistent, minimal color-coded labels (set `NOCOLOR=1` for plain text):

| Label       | Meaning                                                                              |
| ----------- | ------------------------------------------------------------------------------------ |
| **[WARN]**  | Major stage banner, beginning of a subtask, or warning (e.g. MS Build Tools check)   |
| **[INFO]**  | Progress and diagnostic output                                                       |
| **[-OK-]**  | Successful task or step completion                                                   |
| **[ERROR]** | Critical failure causing termination (except expected missing libs in preactivation) |

At the end of a successful installation, you should see an `[OK]` banner as shown below.

**MS Build Tools Check - Failed**

![](./AIFFCV/Screenshots/MSBuild_failed.jpg)

**MS Build Tools Check - Passed**

![](./AIFFCV/Screenshots/MSBuild_passed.jpg)

**Successful Completion**

![](./AIFFCV/Screenshots/completion.jpg)

## 🧱 Overview

The [Fast Forward Computer Vision (FFCV)](https://github.com/libffcv/ffcv) library addresses one of the most common bottlenecks in large-scale AI model training - high-latency data loading from disk to RAM when working with millions of small image files. Its companion project, [Fastxtend](https://github.com/warner-benjamin/fastxtend/), extends FFCV integration to the [fastai](https://github.com/fastai/fastai) ecosystem.

Although both projects nominally support Windows, neither provides functioning Windows installation instructions. FFCV’s setup script (`setup.py`) fails to locate and configure required native dependencies.

This repository documents and automates a working Windows build and installation pipeline for FFCV and Fastxtend using native MS Build Tools and a standalone Micromamba manager - without modifying the upstream sources.

## 🔬 Deep Dive

### Understanding the Build Problem

FFCV installation failures fall into four major categories:  

1. **{LIBRARY} not found** - binaries not on `PATH`.
2. **MSVC compiler missing** - `pip` and `setuptools` often fail to detect MS Build Tools.
3. **Linker errors** - missing or misreferenced `.lib` files.
4. **DLL load failed** - a variety of potential causes

FFCV’s `setup.py` uses `pkgconfig_windows()` to generate compiler and linker flags. On Linux, `pkconfig`-based installation works because directories are standardized; on Windows, paths are fragmented and inconsistent. Further, dependency discovery logic implemented in `setup.py` for Windows is non-sensical and is bound to fail completely.

### Dependency Resolution on Windows

#### Build-Time Requirements

|Stage|Requirement|Description|
|:-:|---|---|
|1|`*.h` headers|Compiler input (C/C++ headers)|
|2|`*.lib` libraries|Linker import libraries|
|3|`*.lib` filenames|Explicit linker targets|
|4|`*.dll` binaries|Runtime dependencies (after build)|

Items (1)-(3) must exist before compilation; (4) must be discoverable on `PATH` at runtime.

#### Key Environment Variables for MSVC Toolchain

| Variable  | Purpose                                                                  |
| --------- | ------------------------------------------------------------------------ |
| `INCLUDE` | Header directories (`*.h`)                                               |
| `LIB`     | Import library directories (`*.lib`)                                     |
| `LINK`    | Additional linker arguments, including names of `*.lib` files to be used |
| `PATH`    | Runtime DLL search paths                                                 |

Predefining these variables should result in a successful build (providing that compatible library versions/variants are used) without modifying `setup.py` (which simply adds non-sensical values, ignored by the toolchain).

### Why Linux Builds Work (and Windows Doesn’t)

Linux uses standard paths like `/usr/include` and `/usr/lib`. Windows doesn’t - each project or installer defines its own. Conda partially standardizes a layout via `Library`:

```
Library/bin/
Library/include/
Library/lib/
```

FFCV doesn’t rely on Conda-provided libraries, so its `pkgconfig_windows` function returns meaningless values. The scripts here pre-set all variables before bootstrapping.

### Automated Environment Layout

```
AIPY/
├─ Anaconda/             ← Micromamba environment
│   ├─ python.exe
│   └─ Library/
├─ pthreads/
│   ├─ dll/x64/pthreadVC2.dll
│   ├─ include/pthread.h
│   └─ lib/x64/pthreadVC2.lib
├─ opencv/
│   └─ build/x64/vc15/
└─ libjpeg-turbo/
```

Activation scripts extend environment variables in the following order:

1. Library-specific paths (pthreads, opencv)    
2. Conda `Library/*` paths
3. System paths (fallback)

This hierarchy prevents conflicts between Conda and system DLLs.

### FFCV `setup.py` Analysis

FFCV’s Windows configuration logic resides in `pkgconfig_windows(package, kw)`.  It is intended to detect headers and libraries automatically, but as of `ffcv==1.0.2`, it yields invalid values.

Example diagnostic injection:

```python
print("==================================================================")
print(package)
print(kw)
print("==================================================================")
```

Output confirms that include/library directories are nonsensical. Rather than patching FFCV, this project injects correct values via environment variables.

### Library Settings

| Library            | Version       | Source         | Integration       |
| ------------------ | ------------- | -------------- | ----------------- |
| **OpenCV**         | 4.6.0 VC15    | Official build | External install  |
| **LibJPEG-Turbo**  | Not specified | Conda package  | Use Conda version |
| **pthreads-win32** | 2.9.1         | Sourceware FTP | External install  |

#### Configuration Summary

|               | pthreads           | OpenCV                      | LibJPEG-Turbo              |
| ------------- | ------------------ | --------------------------- | -------------------------- |
| **`PATH`**    | `pthreads\dll\x64` | `opencv\build\x64\vc15\bin` | `Anaconda\Library\bin`     |
| **`INCLUDE`** | `pthreads\include` | `opencv\build\x64\vc15\lib` | `Anaconda\Library\include` |
| **`LIB`**     | `pthreads\lib\x64` | `opencv\build\include`      | `Anaconda\Library\lib`     |
| **`LINK`**    | `pthreadVC2.lib`   | `opencv_world460.lib`       | `opencv_world460.lib`      |

### Building from Source

Once the environment is initialized, `pip` inherits predefined `INCLUDE`, `LIB`, and `LINK` values, allowing `setuptools` to compile FFCV successfully with MSVC.

## 🗂️ Sample Project Layout

| Script                         | Role                                                   |
| ------------------------------ | ------------------------------------------------------ |
| **Anaconda.bat**               | Main entry point - bootstraps and verifies environment |
| **conda_far.bat**              | Activates MS Build Tools and library environment       |
| **libs.bat**                   | Downloads and extracts library archives                |
| **msbuild.bat**                | Attempts to find and activate MSVC toolchain           |
| **pthreads/activate.bat**      | Sets pthreads variables                                |
| **opencv/activate.bat**        | Sets OpenCV variables                                  |
| **libjpeg-turbo/activate.bat** | Sets LibJPEG-Turbo variables                           |

Each module performs one explicit task and cleans up its variables before returning.

## 📚 References

- [FFCV GitHub Repository](https://github.com/libffcv/ffcv)
- [Fastxtend GitHub Repository](https://github.com/warner-benjamin/fastxtend)
- [Microsoft Visual C++ Build Tools](https://visualstudio.microsoft.com/visual-cpp-build-tools)
- [SO: Installing MS Build Tools for pip](https://stackoverflow.com/a/64262038/17472988)
- [Field Notes: Bootstrapping Python Environments on Windows](https://github.com/pchemguy/Field-Notes/blob/main/03-python-env-windows/README.md)
- [Field Notes: Python pip & MSVC Detection Issues](https://github.com/pchemguy/Field-Notes/blob/main/05-python-pip-msvc/README.md)
