# Building and Installing FFCV on Windows

_A Reproducible Environment Setup Using Micromamba and MS Build Tools_

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
