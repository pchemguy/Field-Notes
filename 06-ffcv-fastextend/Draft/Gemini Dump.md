I have designed a set of `cmd.exe` scripts for automatic bootstrapping of an isolated Python/Conda environment on Windows and building/installation of the FFCV library into the bootstrapped environment. This project will be hosted in a GitHub repository, and I am presently working on the detailed README that should be very helpful to my future self, as well as anyone else interested in the subject. My present view is that the initial section should provide enough relatively high-level details necessary to quickly run it locally. Then the text should develop a comprehensive and cohesive coverage of the various issues I have discovered, their analysis/causes/solutions etc. Importantly, most encountered issues related to the setup and build process might be of general interest to anyone working with custom Python environments on Windows and packages requiring native compilation.

Below, I am embedding my current `README Draft`, my early `BS notes`. and all scripts.

---
`README Draft`


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


---
`BS notes`

# Building and Installation of FFCV on Windows

The [Fast Forward Computer Vision (FFCV) library](https://github.com/libffcv/ffcv) aims to address the data loading bottleneck occurring, for example, when training AI models using a large dataset not fitting within RAM and consisting of large number of small files, such as [ImageNet-1K, ILSVRC2012](https://image-net.org/challenges/LSVRC/2012/). A related project, [Fastxtend](https://github.com/warner-benjamin/fastxtend/), aims to bridge FFCV with [fastai](https://github.com/fastai/fastai). Both FFCV and fastxtend have not been unfortunately updated since 2023, but I wanted to give them a try anyway. I primarily use Windows and both projects claimed Windows support. However, FFCV proved to be quite tricky to get installed.

FFCV's GitHub repository README provides very concise installation instructions, and the initial attempts has unsurprisingly failed. Very first attempts resulted in an error with the trace referring to missing OpenCV package or something. That was the only issue covered by the provided installation instructions.

The next troubleshooting round was due to a confusing message regarding missing Microsoft Visual C++. It was confusing for a couple reasons. On the one hand, I had not anticipated that this package would require compilation (in fact, besides GitHub, FFCV is primarily distributed as a PyPI package, and its [download section](https://pypi.org/project/ffcv/#files) clearly shows that only source code distribution is available). And a major issue, however, was in fact that I installed [MS Build Tools](https://visualstudio.microsoft.com/visual-cpp-build-tools), a native Windows toolchain, which I used before (though I used a separate installation) for direct building (not involving Python). I have previously discussed a Micromamba-based [approach](https://github.com/pchemguy/Field-Notes/blob/main/03-python-env-windows/README.md) to bootstrapping clean Python environments, which does not have a Python dependency. Being able to reproducibly and efficiently bootstrap clean Python environments without the need to use base/system/root Python installation is particularly important for troubleshooting environment configuration problems. While this message may indicate what is say - MS Build Tools not actually being installed, this issues has been covered in various sources, e.g., this [SO answer](https://stackoverflow.com/a/64262038/17472988). I have also covered the causes of Python (actually `pip`/`setuptools`) not seeing activated MSBuild environment in an [SO QA](https://stackoverflow.com/q/79789580) and a [separate post](https://github.com/pchemguy/Field-Notes/blob/main/05-python-pip-msvc/README.md), so I will not cover these issues here.

The third round of troubleshooting yielded an error, which was coming from linker and was characteristic of missing build dependencies - the linker was unable to locate the necessary libraries to resolve certain calls. When managing build dependencies within the Python-pip-setuptools-MSVC Build Tools environment, it is important to realize that some of these dependencies may be available and installed as PyPI/Conda package. Further, some of such packages, in fact, provide only Python bindings without including the files required by the build process, some provide "reduced" library versions which may not provide all the necessary functionality, some provide alternative builds that may or may not be fully compatible (or be outright incompatible) with the project being build, yet others are perfectly fine and can be used without obtaining a separate installation.

While in the ideal world `pip install` would hide all the complex details of the building process, in real world it is not always the case. Whether `pip install` build process would succeed actually to a large extent depends on the authors of the package being built - aspect to large extent beyond the control of `pip`.  The author of the package being built are responsible for creating a setup script that supplies the necessary information to `setuptools` to be used for constructing compiler and linker command lines. In particular, there are three key pieces about dynamic loaded library dependencies that must be provided to the build toolchain for it to successfully resolve external dependencies, with the fourth item being runtime requirement:
1. location of `*.h` header files (typically found within the include directory) for the compiler
2. location of `*.lib` import library files for the linker
3. importantly, specific names of import library files to be used by the linker (compiler uses `#include` directives to identify required header files, but linker does not have a similar guiding about `*.lib` files)
4. location of dll files (this location needs to be on the path, but it is not actually used by the toolchain during the building process; it is required, however, by the built package for it to be able to start and function).
The last position - the location of DLLs - is a runtime requirement, this location must be added to the Path variable (within environment activation script - do not pollute the system Path!) and must be set by the user. Correctly setting the first three positions is essential for the building process to succeed. In theory, the setup script of the package being built must provide the first three items to `setuptools` correctly for it to build compiler/linker commands. The error message from the linker may mean that there is an issue with setup instructions (either on part of their preparation by the author or on part of user following them, or both, including potential paths/names collision) and/or that there is an issue with information provided by the setup script to `setuptools`. In practice, because Linux has a standardized location for installed `*.h` and `*.lib` files, setting configuring dependencies when building on Linux usually requires a simpler associated setup script logic. Windows, on the other hand, does not have a dedicated standard location for `*.h` and `*.lib` files. While avoiding system-wide installation of dependencies, which is more natural on Windows due to lack of a standard location is advantageous for creating isolated tailored environments, lack of standard location complicates the build setup logic, as the setup script must somehow figure this information if attempting to perform automatic configuration without user intervention. Now, names of required `*.lib` files are determined by the library regardless of its actual location and this part should be, generally, less of a problem for the setup script (though there might be some case-by-case nuances).

As far as isolated Python environments are concerned, ideally there could be established a convention for placing dependencies within a dedicated directory either under the environment directory or placing dependencies and the environment directory under the same parent directory. In fact, modern Python environments have a dedicated `Library` directory with `Library/bin`, `Library/include`, and `Library/lib` subdirectories to be used as a shared environment location for library files included in packages. For example, Conda packages `pthreads` and `libjpeg-turbo` include entire libraries (both runtime DLLs and developer/ build-time `*.h` and `*.lib`) and conda/mamba installers place files included in these packages in respective shared directories. `pip install` command is executed in the context of environment as well, so it knows location of the top directory (containing `python.exe`). "Manual" dependencies, that is dependencies not installed as part of Conda packages, may, in principle also added to these directories, though this approach may not be desirable. For once, the contents with an isolated Python environment should be ideally changed only using appropriate package manager, ensuring a reproducible and predictable environment. An alternative approach, is therefore, having a directory structure like the following:

```
AIPY/Anaconda/python.exe
AIPY/pthreads/dll/x64/pthreadVC2.dll
AIPY/pthreads/include/pthread.h
AIPY/pthreads/lib/x64/pthreadVC2.lib
```

Note that `pthreads` directory structure does not follow a certain standard, but is the default structure determined by the library. If the DLL file directory is placed on the path before running `pip install`, the setup script may attempt to locate the required `pthreadVC2.dll` dependency on the path, extract the top-level library directory assuming the directory structure used by the library and deduce location of `*.h` and `*.lib` again based on the library's directory structure. Note that potential DLL name clashes on the path would complicate this process. However, any such clash presents a runtime problem as well, which is why the general system path components should be generally kept at the end of Path variable as a last resort option for going around unavoidable clashes with system libraries. So a relatively robust hierarchy of paths for managing potential runtime DLL name clashes would involve placing library-specific directories on the Path first, followed by environment specific directories, such as `Library/bin`, followed by system directories at the end. In such a case, a situation where some Conda package causes installation of `pthreads` Conda package, which happens to use a non-default binary variant, while using a dedicated default version for a PyPI package, may result in a structure:

```
AIPY/pthreads/dll/x64/pthreadVC2.dll
AIPY/pthreads/include/pthread.h
AIPY/pthreads/lib/x64/pthreadVC2.lib

AIPY/Anaconda/python.exe
AIPY/Anaconda/Library/bin/pthreadVSE2.dll
AIPY/Anaconda/Library/lib/pthread.lib
AIPY/Anaconda/Library/include/pthread.h
```

For certain libraries, a third copy  could be installed with Windows. In this case, there is no DLL name clash, but both names used are official variants. So if setup script is trying to locate any supported official variant, such as these two above, it would match first the library-specific installation first, properly resolving it and building against it, assuming the above Path organization is followed. In fact, a more advanced setup script could readily distinguish between the two versions and use Conda-based version as fallback or the other way around, if appropriate.

Having discussed these issues, we now need examine the `setup.py` script of FFCV, located at the top-level of the distributed source package in an attempt to troubleshoot the installation process. Because I am not proficient with this matter, I actually fed the script to Google Gemini for AI-assisted analysis. The LLM pointed out that under Windows, the relevant section of the script is the `def pkgconfig_windows(package, kw):` routine. This routine attempts to process each dependency and deduce required paths/names for `setuptools`, which, in turn, translates them into appropriate compiler/linker command line switches. Additional insights into what this routine produces can be gained by inserting lines

```python
    print("==================================================================")
    print(package)
    print(kw)
    print("==================================================================")
```

at the bottom of the `pkgconfig_windows` routine immediately preceding `return kw`, following by running local build with within unpacked source package directory

```
python setup.py build_ext --inplace
```

 Additionally, because the dictionary `kw` is incrementally extended with each dependency via calls from the following code, it makes sense to place the dependency of interest first to see its associated `kw` values.

Further AI-assisted analysis revealed that `pkgconfig_windows` logic (ffcv-1.0.2) is not that much better than choosing random directories and file names, so basically absolute nonsense and it is unclear whether it has ever been actually tested or worked. To install FFCV on Windows, therefore, the setup script needs to be fixed following by installation from local source copy. However, I would rather avoided meddling in the source code, if possible, keeping the environment installation process unaffected. Basically, what the present code does, it passes random useless paths/file names to compiler/linker. At the same time, these options are essentially NOOP within the present context, doing no harm, except for some inconsequential extra unnecessary processing. The idea is than to have environment setting script (or scripts) that determine correct paths/files for the build process before initiating package installation process. Because I am, not aware of the ability to provide correct options via `pip` command line, we can take advantage of an alternative approach, that is setting relevant environment variables (interpreted by compiler/linker directly) inherited first by the `pip` process and then passed to the environments of spawn compiler/linker processes. The relevant variables are as follows: 
- `INCLUDE` - Header file directories
- `LIB`- Import library directories
- `LINK` - General-purpose variable for command line MS linker switches. Names of import library files should be provided in the linker command line as is without any switches, so they are added as space-separated lists to this variable.
If this variables are correctly set before environment bootstrapping process, `FFCV` build process should, hopefully, succeed.

## Library settings

As can be seen from `setup.py`, FFCV has three build-time dependencies:
- [OpenCV](https://opencv.org/releases)
  FFCV's README only indicates major version requirement (as opencv4), but it does not indicate minor version requirements. However, the Windows installation section refers to `/opencv/build/x64/vc15/bin`, indicating VC15-based OpenCV. Whether VC16-based versions would work just as well would need to be tested. The latest VC15-based version was 4.6.0.
- LibJPEG-Turbo
  FFCV's README does not indicate version requirement. However, it links the old [SF repo](https://sourceforge.net/projects/libjpeg-turbo/files/) with the most recent version being 3.0.1. More newer versions are available from a [GitHub repo](https://github.com/libjpeg-turbo/libjpeg-turbo).
- [pthreads-win32](https://sourceware.org/pthreads-win32) ([latest release](ftp://sourceware.org/pub/pthreads-win32/pthreads-w32-2-9-1-release.zip))

Each of the tree libraries has associated Conda package, containing both runtime (`*.dll`) and build-time (`*.h` and `*.lib`) dependencies. When creating a Conda environment per specification indicated by FFCV installation instructions, all three packages are getting installed into the `Library` subdirectory. All Conda binaries differ from the official releases. Conda's OpenCV build appears to be incompatible with the official release; LibJPEG-Turbo versions appear to be compatible (so Conda package is used for the current build), whereas pthreads package includes a binary variant which appears to be generally compatible.

Often, libraries available as Conda packages that include actual libraries (not just Python bindings) can be used to fulfill DLL dependencies when building other Conda packages from source. Because modern Conda packages install DLLs and build-time dependencies in a standardized location within the environment and relative to its parent directory, building configuration can be substantially simplified. On the other hand, care must be taken when using components of Conda ecosystem for fulfilling dependencies of non-Conda packages, such as PyPI. In the present example, I decided to build FFCV using external copy of pthreads and OpenCV, while using Conda's LibJPEG-Turbo package.

While this build succeeded, it is a risky solution, because of increased risk of name clashes (both header files and binaries may potentially experience this issue) for the following reason. As mentioned above, all modern Conda packages should place library header files within `Library/include`, import libraries within `Library/lib`, and binaries within `Library/bin`, following shared directory structure organization used by Linux. The standard `conda activate` command adds `Library/bin` to the Path, but the two other directories are not added to `INCLUDE` and `LIB`. Activation of any package within this ecosystem mean providing `lib` and `include` libraries to compiler/linker, making all installed packages visible. Now, with the chosen scheme of using LibJPEG-Turbo Conda package, I have to activate this ecosystem. Because I use official variants of the two other libraries, these external versions may clash with their Conda counterparts because of the activated `Library` location.

### pthreads

By examining the directory with prebuilt binaries (renamed to `pthreads` following the FFCV instructions), we deduce:
- `pthreads/dll/x64` needs to be added to `Path` (DLL name `pthreadVC2.dll`)
- `pthreads/include` needs to be added to `INCLUDE` (header file `pthread.h`)
- `pthreads/lib/x64` needs to be added to `LIB`, while also passing `pthreadVC2.lib` to linker.

### OpenCV

The contents of `opencv-4.6.0-vc14_vc15/opencv/build` directory has been moved to `opencv`. According to hints in FFCV instructions, the settings are as follows:
- `opencv/build/include` - `INCLUDE`
- `opencv/build/x64/vc15/bin` - `Path`
- `opencv/build/x64/vc15/lib` - `LIB` and `opencv_world460.lib` should be passed to the linker (the variant with `d` suffix apparently stands for "debug")

### LibJPEG-Turbo

Because using Conda's package, relevant directories are indicated above. By examining the official distro, I determined that the relevant `*.lib` file `turbojpeg.lib`.

### Selection Crosscheck

This package has relatively simple dependency configuration. While there usually one directory for each `Path`/`INCLUDE`/`LIB` variable per dependency, more than one `*.lib` file may need to be specified. Aldo, we can do a simple "crosscheck" by searching the source directory for modules including selected header files. Usually, header files, import libraries and DLLs have related names, so whether the correct `*.lib` file is selected can be roughly checked by looking into included header file names.

## Sample Project

This repository contains a sample project designed to bootstrap an FFCV/fastxtend Conda environment with minimal prerequisites 


---
`AIFFCV/Anaconda.bat`

```
@echo off
setlocal EnableDelayedExpansion EnableExtensions

:: ============================================================================
::  Purpose:
::    Bootstraps a fully functional Conda/Micromamba-based Python environment
::    for Windows builds of FFCV and Fastxtend. This script is the primary
::    entry point for first-time setup, automating dependency acquisition,
::    environment creation, and validation.
::
::  Description:
::    Performs all prerequisite checks, downloads required native libraries,
::    installs Micromamba, and constructs both the minimal bootstrap and the
::    full development environment defined by corresponding YAML files.
::    Ensures that the resulting environment is ready for immediate use with
::    downstream scripts such as "conda_far.bat".
::
::  Workflow Summary:
::      1. Verify system prerequisites:
::           - NVIDIA GPU drivers
::           - curl and tar availability
::           - cmd.exe Delayed Expansion enabled
::           - Required helper scripts present (msbuild.bat, libs.bat, conda_far.bat)
::      2. Set up and verify cache directories for package storage.
::      3. Download pthreads, OpenCV, and libjpeg-turbo libraries via libs.bat.
::      4. Retrieve the latest Micromamba binary (Windows x64).
::      5. Create a new environment using the bootstrap YAML file.
::      6. Activate and extend the environment with the main YAML definition.
::      7. Export the final frozen environment file (_generated.yml).
::      8. Validate imports of ffcv and fastxtend to confirm success.
::
::  Notes:
::      - Designed for Windows 10+ systems with ANSI color support.
::      - Requires curl.exe and tar.exe in PATH (included with modern Windows).
::      - Requires MS Build Tools for pip/setuptools-initiated native compilation.
::      - Honors the NOCOLOR variable to disable colorized output.
::      - Must be run from a clean cmd.exe shell (no preactivated Python/Conda).
::      - Automatically reuses cached downloads to minimize redundant fetches.
::      - Creates a Python environment based on two YAML files:
::
::  Invocation Modes:
::      (no argument) - Verbose (-v)
::      /q            - Quite Mamba/Conda output.
::
::  Core YAML files:
::      - <script>_bootstrap.yml   - minimal bootstrap environment
::                                   Python/Conda/Mamba/UV
::      - <script>.yml             - main environment definition
::      - <script>_generated.yml   - generated full final resolved environment
::
::  Exit Codes:
::      0  - Success
::      1+ - Failure during environment or dependency setup
::
::  Related Scripts:
::      msbuild.bat     – Activates MS Build Tools environment.
::      libs.bat        – Downloads and activates native libraries.
::      conda_far.bat   – Initializes and activates full Conda environment.
:: ============================================================================

echo :========== ========== ========== ========== ==========:
echo  Bootstrapping Python Environment
echo :---------- ---------- ---------- ---------- ----------:
rem           ----- Mon 10/20/2025 21:03:09.88 -----
echo:         ----- %DATE% %TIME% -----
echo: CLI: "%~f0" %*
echo:

:: --- Escape sequence templates for color coded console output ---

call :COLOR_SCHEME

:: --- Determine base components of environment path and check for existing Python ---

set "_ENV_PREFIX=%~dpn0"
if exist "%_ENV_PREFIX%\python.exe" (
  echo %WARN% Found existing "%_ENV_PREFIX%\python.exe". Skip bootstrapping...
  goto :CLEANUP
)

:: --- Check prerequisites ---

call :PREREQUISITES
if not "%ERRORLEVEL%"=="0" (
  set "FINAL_EXIT_CODE=%ERRORLEVEL%"
  echo %ERROR% Failed prerequisite checks. See error above. Aborting...
  goto :CLEANUP
)

:: --------------------------------------------------------
:: BASE CONFIG
:: --------------------------------------------------------
set "YAML_BOOTSTRAP=%~dpn0_bootstrap.yml"
if not exist "!YAML_BOOTSTRAP!" (
  echo %ERROR% Bootstrap environment file "!YAML_BOOTSTRAP!" not found. Aborting...
  set "FINAL_EXIT_CODE=1"
  goto :CLEANUP
)
echo %INFO% Using bootstrap environment file "!YAML_BOOTSTRAP!".

set "YAML=%~dpn0.yml"
if not exist "!YAML!" (
  echo %ERROR% Main environment file "!YAML!" not found. Aborting...
  set "FINAL_EXIT_CODE=1"
  goto :CLEANUP
)
echo %INFO% Using bootstrap environment file "!YAML!".

:: --------------------------------------------------------
:: VERBOSITY
:: --------------------------------------------------------
set "VERBOSE="
if /I "%~1"==""    set "VERBOSE=-v"
if /I "%~1"=="/q"  set "VERBOSE="

:: --------------------------------------------------------
:: Determine cache directory
:: --------------------------------------------------------
if not defined _CACHE (
  call :CACHE_DIR
  set "EXIT_STATUS=!ERRORLEVEL!"
) else (
  set "EXIT_STATUS=0"
)
if not defined _CACHE (
  echo %ERROR% Failed to set CACHE directory. Aborting...
  set "FINAL_EXIT_CODE=1"
  goto :CLEANUP
)
echo:
pause

:: --------------------------------------------------------
:: Download Libraries
:: --------------------------------------------------------
call "%~dp0libs.bat"
set "EXIT_STATUS=!ERRORLEVEL!"
if not "%ERRORLEVEL%"=="0" (
  set "FINAL_EXIT_CODE=%ERRORLEVEL%"
  echo %ERROR% Failed to obtain libraries. ERRORLEVEL: %EXIT_STATUS%. Script: "%~dp0libs.bat". Aborting...
  goto :CLEANUP
)
call :COLOR_SCHEME

:: --------------------------------------------------------
:: Download Micromamba
:: --------------------------------------------------------
call :MICROMAMBA_DOWNLOAD
if not "%ERRORLEVEL%"=="0" (
  set "FINAL_EXIT_CODE=%ERRORLEVEL%"
  echo %ERROR% Downloading micromamba. Aborting...
  goto :CLEANUP
)

:: --------------------------------------------------------
:: Bootstrap new Python/Conda/Mamba/UV environment
:: --------------------------------------------------------
call :BOOTSRTAP_ENV
if not "%ERRORLEVEL%"=="0" (
  set "FINAL_EXIT_CODE=%ERRORLEVEL%"
  echo %ERROR% Failed to bootsrap Python/Conda/Mamba/UV environment. Aborting...
  goto :CLEANUP
)

:: --------------------------------------------------------
:: Activate new Python/Conda/Mamba/UV environment
:: --------------------------------------------------------
call :ACTIVATE_ENV
if not "%ERRORLEVEL%"=="0" (
  set "FINAL_EXIT_CODE=%ERRORLEVEL%"
  echo %ERROR% Failed to activate the new Python/Conda/Mamba/UV environment. Aborting...
  goto :CLEANUP
)

:: --------------------------------------------------------
:: Import main environment
:: --------------------------------------------------------
call :IMPORT_MAIN_ENV
if not "%ERRORLEVEL%"=="0" (
  set "FINAL_EXIT_CODE=%ERRORLEVEL%"
  echo %ERROR% Failed to import main environment. Aborting...
  goto :CLEANUP
)

:: --------------------------------------------------------
:: Copy DLLs to CONDA_PREFIX
:: --------------------------------------------------------
call :COPY_DLLS
if not "%ERRORLEVEL%"=="0" (
  set "FINAL_EXIT_CODE=%ERRORLEVEL%"
  echo %ERROR% Failed to copy DLLs to CONDA_PREFIX. Aborting...
  goto :CLEANUP
)

:: --------------------------------------------------------
:: Export full environment
:: --------------------------------------------------------
call :EXPORT_FULL_ENV
if not "%ERRORLEVEL%"=="0" (
  set "FINAL_EXIT_CODE=%ERRORLEVEL%"
  echo %ERROR% Failed to export full environment. Aborting...
  goto :CLEANUP
)

:: --------------------------------------------------------
:: Verify FFCV
:: --------------------------------------------------------
call :VERIFY_ENV
if not "!ERRORLEVEL!"=="0" (
  set "FINAL_EXIT_CODE=%ERRORLEVEL%"
  echo %ERROR% Failed to verify FFCV. ERRORLEVEL: !EXIT_STATUS!. Script: "%~dp0libs.bat". Aborting...
  goto :CLEANUP
)

echo:
rem                   ----- Mon 10/20/2025 21:03:09.88 -----
echo:                 ----- %DATE% %TIME% -----
echo ====================================================================================
echo ====================================================================================
echo == %OKOK%                                                            %OKOK% ==
echo == %OKOK%      FFCV environment created and verified successfully.   %OKOK% ==
echo == %OKOK%                                                            %OKOK% ==
echo ====================================================================================
echo ====================================================================================
echo:

set "FINAL_EXIT_CODE=0"
goto :CLEANUP
:: ============================================================================
:: ============================================================================
:: ============================================================================


:: ============================================================================ CLEANUP BEGIN
:: ============================================================================
:: --- Clean up; prefer as the primary script exit point ---
:: To exit script, set FINAL_EXIT_CODE and goto CLEANUP
:CLEANUP

:: --- Ensure a valid exit code is always returned ---

if not defined FINAL_EXIT_CODE set "FINAL_EXIT_CODE=1"
exit /b %FINAL_EXIT_CODE%
:: ============================================================================ 
:: ============================================================================ CLEANUP END


:: ============================================================================ COLOR_SCHEME BEGIN
:: ============================================================================
:COLOR_SCHEME
:: ---------------------------------------------------------------------
:: Color Scheme (with NOCOLOR fallback)
:: ---------------------------------------------------------------------

if defined NOCOLOR (
  set  "INFO= [INFO]  "
  set  "OKOK= [-OK-]  "
  set  "WARN= [WARN]  "
  set "ERROR= [ERROR] "
) else (
  set  "INFO=[100;92m [INFO]  [0m"
  set  "OKOK=[103;94m [-OK-]  [0m"
  set  "WARN=[106;35m [WARN]  [0m"
  set "ERROR=[105;34m [ERROR] [0m"
)

exit /b 0
:: ============================================================================ 
:: ============================================================================ COLOR_SCHEME END


:: ============================================================================ CACHE_DIR BEGIN
:: ============================================================================
:CACHE_DIR
:: --------------------------------------------------------
:: Determine cache directory
:: --------------------------------------------------------
if exist "%_CACHE%" (
  goto :CACHE_DIR_SET
) else (
  set "_CACHE=%TEMP%"
)

if exist "%~d0\CACHE" (
  set "_CACHE=%~d0\CACHE"
  goto :CACHE_DIR_SET
)

if exist "%~dp0CACHE" (
  set "_CACHE=%~dp0CACHE"
  goto :CACHE_DIR_SET
)

if exist "%USERPROFILE%\Downloads" (
  if exist "%USERPROFILE%\Downloads\CACHE" (
    set "_CACHE=%USERPROFILE%\Downloads\CACHE"
  ) else (
    set "_CACHE=%USERPROFILE%\Downloads"
  )
  goto :CACHE_DIR_SET
)

:CACHE_DIR_SET
:: --------------------------------------------------------
:: Verify file system access
:: --------------------------------------------------------
set "_DUMMY=%_CACHE%\$$$_DELETEME_ACCESS_CHECK_$$$"
if exist "%_DUMMY%" rmdir /Q /S "%_DUMMY%"
set "EXIT_STATUS=%ERRORLEVEL%"
if exist "%_DUMMY%" set "EXIT_STATUS=1"
if not "!EXIT_STATUS!"=="0" (
  echo %ERROR% Failed to delete test directory "%_DUMMY%".
  echo %ERROR% Expected a full-access at this location "%_CACHE%".
  echo %ERROR% Aborting...
  set "_CACHE="
  exit /b !EXIT_STATUS!
)

md "%_DUMMY%"
set "EXIT_STATUS=%ERRORLEVEL%"
if not exist "%_DUMMY%" set "EXIT_STATUS=1"
if not "!EXIT_STATUS!"=="0" (
  echo %ERROR% Failed to create test directory "%_DUMMY%".
  echo %ERROR% Expected a full-access at this location "%_CACHE%".
  echo %ERROR% Aborting...
  set "_CACHE="
  exit /b !EXIT_STATUS!
)

:: --------------------------------------------------------
:: Point CONDA_PKGS_DIRS and PIP_CACHE_DIR to package cache directory
:: --------------------------------------------------------
set "_PKGS_DIR=%_CACHE%\Python\pkgs"

if not defined CONDA_PKGS_DIRS (
  set "CONDA_PKGS_DIRS=%_PKGS_DIR%"
) else (
  set "_PKGS_DIR=%CONDA_PKGS_DIRS%"
)
if not exist "%CONDA_PKGS_DIRS%" md "%CONDA_PKGS_DIRS%"
if not "%ERRORLEVEL%"=="0" (
  echo %ERROR% Failed to create directory "%CONDA_PKGS_DIRS%".
  set "_CACHE="
  exit /b !EXIT_STATUS!
)
set "PIP_CACHE_DIR=%_CACHE%\Python\pip"

echo %INFO% CACHE directory: "%_CACHE%".
echo %INFO% CONDA_PKGS_DIRS directory: "%CONDA_PKGS_DIRS%".
echo %INFO% PIP_CACHE_DIR   directory: "%PIP_CACHE_DIR%".

exit /b 0
:: ============================================================================
:: ============================================================================ CACHE_DIR END


:: ============================================================================ MICROMAMBA_DOWNLOAD BEGIN
:: ============================================================================
:MICROMAMBA_DOWNLOAD

:: --------------------------------------------------------
:: Download Micromamba
:: --------------------------------------------------------
echo %WARN% Micromamba
set "RELEASE_URL=https://github.com/mamba-org/micromamba-releases/releases/latest/download/micromamba-win-64"
set "MAMBA_EXE=%_CACHE%\micromamba\micromamba.exe"
if not exist "%_CACHE%\micromamba" md "%_CACHE%\micromamba"
set "EXIT_STATUS=!ERRORLEVEL!"
if not "%EXIT_STATUS%"=="0" (
  echo %ERROR% Creating "%_CACHE%\micromamba". Aborting...
  exit /b %EXIT_STATUS%
)
if exist "%MAMBA_EXE%" (
  echo %INFO% Micromamba: Using cached "%MAMBA_EXE%"
) else (
  echo %INFO% Micromamba: Downloading: %RELEASE_URL%
  echo %INFO% Micromamba: Destination: %MAMBA_EXE%
  curl --fail --retry 3 --retry-delay 2 -L -o "%MAMBA_EXE%" "%RELEASE_URL%"
  set "EXIT_STATUS=!ERRORLEVEL!"
  if not "!EXIT_STATUS!"=="0" (
    echo %ERROR% Micromamba: Download failure. Aborting bootstrapping...
    exit /b !EXIT_STATUS!
  )
)
set "RELEASE_URL="
if not exist "%MAMBA_EXE%" (
  echo %ERROR% Micromamba: File "%MAMBA_EXE%" missing after download. Aborting...
  exit /b 1
)
echo %OKOK% Micromamba: Completed
echo:

exit /b 0
:: ============================================================================
:: ============================================================================ MICROMAMBA_DOWNLOAD END


:: ============================================================================ BOOTSRTAP_ENV BEGIN
:: ============================================================================
:BOOTSRTAP_ENV

:: --------------------------------------------------------
:: Bootstrap new Python/Conda/Mamba/UV environment
:: --------------------------------------------------------
echo:
rem                   ----- Mon 10/20/2025 21:03:09.88 -----
echo:                 ----- %DATE% %TIME% -----
echo ====================================================================================
echo ====================================================================================
echo == %WARN%                                                            %WARN% ==
echo == %WARN%           Bootstrapping new Python environment             %WARN% ==
echo == %WARN%           Python/Conda/Mamba/UV                            %WARN% ==
echo == %WARN%                                                            %WARN% ==
echo ====================================================================================
echo ====================================================================================
echo:
rem set "PKGS=mamba conda uv %_PYTHON_PKG%"

if exist "%APPDATA%\mamba" (
  echo %WARN% Warning: I am about to delete "%APPDATA%\mamba". Press any key to continue.
  echo %WARN% Somehow, Micromamba tends to hang when this directory exists.
  pause
  rmdir /Q /S "%APPDATA%\mamba"
  set "EXIT_STATUS=!ERRORLEVEL!"
  if not "!EXIT_STATUS!"=="0" (
    echo %ERROR% Failed to delete "%APPDATA%\mamba". ERRORLEVEL: %EXIT_STATUS%. Aborting...
    exit /b %EXIT_STATUS%
  )
)

echo %WARN% Creating new Python environment...
echo %INFO% Using command:
echo %INFO% === "%MAMBA_EXE%" create %VERBOSE% --yes --no-rc --use-uv -f "%YAML_BOOTSTRAP%" --prefix "%_ENV_PREFIX%" %PKGS% ===
echo %INFO%
echo:
call "%MAMBA_EXE%" create %VERBOSE% --yes --no-rc --use-uv -f "%YAML_BOOTSTRAP%" --prefix "%_ENV_PREFIX%" %PKGS%
set "EXIT_STATUS=%ERRORLEVEL%"
if not "%EXIT_STATUS%"=="0" (
  echo %ERROR% Failed to create a new environment. ERRORLEVEL: %EXIT_STATUS%. Aborting...
  exit /b %EXIT_STATUS%
)

echo %OKOK% New environment "%_ENV_PREFIX%" is bootstrapped from "%YAML_BOOTSTRAP%".
exit /b 0
:: ============================================================================
:: ============================================================================ BOOTSRTAP_ENV END


:: ============================================================================ ACTIVATE_ENV BEGIN
:: ============================================================================
:ACTIVATE_ENV

echo:
rem                   ----- Mon 10/20/2025 21:03:09.88 -----
echo:                 ----- %DATE% %TIME% -----
echo ====================================================================================
echo ====================================================================================
echo == %WARN%                                                            %WARN% ==
echo == %WARN%            Activate development environment.               %WARN% ==
echo == %WARN%                                                            %WARN% ==
echo ====================================================================================
echo ====================================================================================
echo:

set "_CONDA_PREFIX=%_ENV_PREFIX%"
call "%~dp0conda_far.bat" /preactivate
set "EXIT_STATUS=!ERRORLEVEL!"
if not "%EXIT_STATUS%"=="0" (
  echo %ERROR% Failed to activate environment "%_ENV_PREFIX%". Aborting...
  exit /b %EXIT_STATUS%
)
set "_CONDA_PREFIX="

if not exist "%CONDA_PREFIX%\python.exe" (
  echo %ERROR% Python not found in "%CONDA_PREFIX%". Aborting...
  exit /b 1
)
call "%CONDA_PREFIX%\python.exe" --version
set "EXIT_STATUS=!ERRORLEVEL!"
if not "%EXIT_STATUS%"=="0" (
  echo %ERROR% Failed to call Python in "%_ENV_PREFIX%". Aborting...
  exit /b %EXIT_STATUS%
)
call :COLOR_SCHEME

echo %OKOK% New environment "%_ENV_PREFIX%" is activated.
exit /b 0
:: ============================================================================
:: ============================================================================ ACTIVATE_ENV END


:: ============================================================================ IMPORT_MAIN_ENV BEGIN
:: ============================================================================
:IMPORT_MAIN_ENV
:: --------------------------------------------------------
:: Import main environment
:: --------------------------------------------------------
echo:
rem                   ----- Mon 10/20/2025 21:03:09.88 -----
echo:                 ----- %DATE% %TIME% -----
echo ====================================================================================
echo ====================================================================================
echo == %WARN%                                                            %WARN% ==
echo == %WARN%           Importing main Python environment                %WARN% ==
echo == %WARN%                                                            %WARN% ==
echo ====================================================================================
echo ====================================================================================
echo:
echo %INFO% YAML:   "%YAML%"
echo %INFO% PREFIX: "%CONDA_PREFIX%"
echo %INFO%

call "%MAMBA_BAT%" env update %VERBOSE% --yes --no-rc --use-uv -f "%YAML%" --prefix "%CONDA_PREFIX%"
set "EXIT_STATUS=!ERRORLEVEL!"
echo:
if not "%EXIT_STATUS%"=="0" (
  echo %ERROR% Failed to import main environment "%_ENV_PREFIX%". Aborting...
  exit /b %EXIT_STATUS%
)

echo %OKOK% Imported main environment "%YAML%" to "%_ENV_PREFIX%".
exit /b 0
:: ============================================================================
:: ============================================================================ IMPORT_MAIN_ENV END


:: ============================================================================ COPY_DLLS BEGIN
:: ============================================================================
:COPY_DLLS
echo:
rem                   ----- Mon 10/20/2025 21:03:09.88 -----
echo:                 ----- %DATE% %TIME% -----
echo ====================================================================================
echo ====================================================================================
echo == %WARN%                                                            %WARN% ==
echo == %WARN%               Copy Libraries to CONDA_PREFIX               %WARN% ==
echo == %WARN%                                                            %WARN% ==
echo ====================================================================================
echo ====================================================================================
echo:
call "%~dp0libs.bat" /install
set "EXIT_STATUS=!ERRORLEVEL!"
if not "%EXIT_STATUS%"=="0" (
  echo %ERROR% Failed to copy libraries to CONDA_PREFIX. ERRORLEVEL: %EXIT_STATUS%. Script: "%~dp0libs.bat". Aborting...
  exit /b %EXIT_STATUS%
)
call :COLOR_SCHEME

echo %OKOK% Copied libraries to CONDA_PREFIX.
exit /b 0
:: ============================================================================
:: ============================================================================ COPY_DLLS END


:: ============================================================================ EXPORT_FULL_ENV BEGIN
:: ============================================================================
:EXPORT_FULL_ENV
echo:
rem                   ----- Mon 10/20/2025 21:03:09.88 -----
echo:                 ----- %DATE% %TIME% -----
echo ====================================================================================
echo ====================================================================================
echo == %WARN%                                                            %WARN% ==
echo == %WARN%           Exporting final full environment file            %WARN% ==
echo == %WARN%                                                            %WARN% ==
echo ====================================================================================
echo ====================================================================================
echo:
echo %INFO% Exporting final full environment file to "%YAML:.yml=_generated.yml%".

call "%CONDA_BAT%" env export --no-builds > "%YAML:.yml=_generated.yml%"
set "EXIT_STATUS=!ERRORLEVEL!"
if not "!EXIT_STATUS!"=="0" (
  echo %ERROR% Failed to export environment file. Aborting...
  exit /b %EXIT_STATUS%
)

echo %OKOK% Exported full environment to "%YAML:.yml=_generated.yml%".
exit /b 0
:: ============================================================================
:: ============================================================================ EXPORT_FULL_ENV END


:: ============================================================================ VERIFY_ENV BEGIN
:: ============================================================================
:VERIFY_ENV
echo:
rem                        ----- Mon 10/20/2025 21:03:09.88 -----
echo:                      ----- %DATE% %TIME% -----
echo ====================================================================================
echo ====================================================================================
echo == %WARN%                                                            %WARN% ==
echo == %WARN%                   Verifying installation:                  %WARN% ==
echo == %WARN%              python -c "import ffcv, fastxtend"            %WARN% ==
echo == %WARN%                                                            %WARN% ==
echo ====================================================================================
echo ====================================================================================
echo:
"%CONDA_PREFIX%\python.exe" -c "import ffcv, fastxtend"
set "EXIT_STATUS=%ERRORLEVEL%"
if not "%EXIT_STATUS%"=="0" (
  echo %ERROR% Failed to import ffcv, fastxtend. Aborting...
  exit /b %EXIT_STATUS%
)

echo %OKOK% Imported ffcv, fastxtend successfully.
exit /b 0
:: ============================================================================
:: ============================================================================ VERIFY_ENV END


:: ============================================================================ EXTRA_ENV BEGIN
:: ============================================================================
:EXTRA_ENV

:: --- Not currently used. Keeping for now for potential use. ---

setlocal
:: --------------------------------------------------------
:: Import additional environment
:: --------------------------------------------------------
echo:
echo %INFO% EXTRA ENVIRONMENTS

:: --------------------------------------------------------
:: Activate environment
:: --------------------------------------------------------
if defined CONDA_PREFIX goto :SKIP_EXTRA_ACTIVATION
call "%~dp0conda_far.bat" /batch
set "EXIT_STATUS=!ERRORLEVEL!"
if not "%EXIT_STATUS%"=="0" (
  echo %ERROR% Failed to activate environment "%_ENV_PREFIX%". Aborting...
  exit /b %EXIT_STATUS%
)
call python.exe --version
set "EXIT_STATUS=!ERRORLEVEL!"
if not "%EXIT_STATUS%"=="0" (
  echo %ERROR% Failed to call Python in "%_ENV_PREFIX%". Aborting...
  exit /b %EXIT_STATUS%
)
:SKIP_EXTRA_ACTIVATION

:: --------------------------------------------------------
:: Command line environment
:: --------------------------------------------------------
echo:
echo %INFO% CHECKING COMMAND LINE EXTRA ENVIRONMENT

set "YAML_EXTRA=%~1"
if not defined YAML_EXTRA goto :SKIP_ARG_YAML
if /I not "%YAML_EXTRA:~-4%"==".yml" (
  echo %WARN% First argument is not *.yml: "%YAML_EXTRA%". Skipping...
  goto :SKIP_ARG_YAML
)
if not exist "%YAML_EXTRA%" (
  echo %WARN% "%YAML_EXTRA%" does not exist. Skipping...
  goto :SKIP_ARG_YAML
)

echo %INFO% importing environment file "%YAML_EXTRA%".
rem mamba hangs with Python 3.9 (not clear if the old Python version causes specific problems here)?
rem call "%MAMBA_BAT%" env update -vv --yes --no-rc --use-uv -f "%YAML_EXTRA%" --prefix "%_ENV_PREFIX%"

call "%CONDA_BAT%" env update -v -f "%YAML_EXTRA%" --prefix "%_ENV_PREFIX%"

:SKIP_ARG_YAML
:: --------------------------------------------------------
:: Default extra environment
:: --------------------------------------------------------
echo:
echo %INFO% CHECKING DEFAULT EXTRA ENVIRONMENT

set "YAML_EXTRA=%YAML:~0,-4%_Extra_Default.yml"
if exist "%YAML_EXTRA%" (
  echo %INFO% Found default extra env file "%YAML_EXTRA%". Importing...
  call "%CONDA_BAT%" env update -v -f "%YAML_EXTRA%" --prefix "%_ENV_PREFIX%"
)

endlocal & exit /b 0
:: ============================================================================
:: ============================================================================ EXTRA_ENV END


:: ============================================================================ PREREQUISITES BEGIN
:: ============================================================================
:: --------------------------------------------------------
:: CHECK Prerequisites
:: --------------------------------------------------------
:PREREQUISITES

rem                       ----- Mon 10/20/2025 21:03:09.88 -----
echo:                     ----- %DATE% %TIME% -----
echo ====================================================================================
echo ====================================================================================
echo == %WARN%                                                            %WARN% ==
echo == %WARN% PREREQS: Checking prerequisites.                           %WARN% ==
echo == %WARN% PREREQS: Inspect results and make sure that all tests are  %WARN% ==
echo == %WARN%          OK and no ERRORs reported before continuing.      %WARN% ==
echo == %WARN%                                                            %WARN% ==
echo ====================================================================================
echo ====================================================================================
echo:

:: --------------------------------------------------------
:: NVidia GPU Driver Information
:: --------------------------------------------------------
echo %WARN% PREREQS - NVIDIA GPU

where nvidia-smi.exe 1>nul 2>&1
set "EXIT_STATUS=%ERRORLEVEL%"
if "%EXIT_STATUS%"=="0" (
  call nvidia-smi.exe
  set "EXIT_STATUS=!ERRORLEVEL!"
) else (
  set "EXIT_STATUS=-1"
)

if "!EXIT_STATUS!"=="0" (
  echo %OKOK% PREREQS - NVIDIA GPU: See GPU driver information above.
) else (
  if "!EXIT_STATUS!"=="-1" (
    echo %ERROR% PREREQS - NVIDIA GPU: nvidia-smi.exe not found. Check NVidia driver installation and environment.
  ) else (
    echo %ERROR% PREREQS - NVIDIA GPU: Failed to obtain NVidia driver information via nvidia-smi.exe.
  )
)
echo:

:: --------------------------------------------------------
:: Required scripts
:: --------------------------------------------------------
echo %WARN% PREREQS - Scripts

:: --- conda_far.bat ---

if exist "%~dp0conda_far.bat" (
  echo %OKOK% PREREQS - Scripts: Conda wrapper script found: "%~dp0conda_far.bat". 
) else (
  echo %ERROR% PREREQS - Scripts: Conda wrapper script not found: "%~dp0conda_far.bat". Aborting...
  exit /b 1
)
echo:

:: --- Libraries script ---

if exist "%~dp0libs.bat" (
  echo %OKOK% PREREQS - Scripts: Library activation script found: "%~dp0libs.bat".
) else (
  echo %ERROR% PREREQS - Scripts: Library activation script not found: "%~dp0libs.bat". Aborting...
  exit /b 1
)
echo:

:: --- MS Build Tools ---

if exist "%~dp0msbuild.bat" (
  echo %OKOK% PREREQS - Scripts: MSBuild activation script found: "%~dp0msbuild.bat".
) else (
  echo %ERROR% PREREQS - Scripts: MSBuild activation script not found: "%~dp0msbuild.bat". Aborting...
  exit /b 1
)
call "%~dp0msbuild.bat"
if not "%ERRORLEVEL%"=="0" (
  echo %ERROR% PREREQS - Scripts: MSBuild activation failed - "%~dp0msbuild.bat". Aborting...
  exit /b 1
)
call :COLOR_SCHEME
echo:

:: --------------------------------------------------------
:: curl and tar
:: --------------------------------------------------------
echo %WARN% PREREQS - Standard Tools

where curl.exe 1>nul 2>&1
if "%ERRORLEVEL%"=="0" (
  echo %OKOK% PREREQS - Standard Tools: curl is ok.
) else (
  echo %ERROR% PREREQS - Standard Tools: curl is not found.
  exit /b 1
)

where tar.exe 1>nul 2>&1
if "%ERRORLEVEL%"=="0" (
  echo %OKOK% PREREQS - Standard Tools: tar is ok.
) else (
  echo %ERROR% PREREQS - Standard Tools: tar is not found.
  exit /b 1
)
echo:

exit /b 0
:: ============================================================================ 
:: ============================================================================ PREREQUISITES END
```

---
`AIFFCV/conda_far.bat`

```
@echo off

:: ============================================================================
::  Purpose:
::    Orchestrates initialization and activation of a minimal Conda-based
::    development environment for Windows-based FFCV/fastxtend builds.
::    Ensures correct setup of MS Build Tools, Conda/Micromamba environment,
::    and native library dependencies (pthreads, OpenCV, libjpeg-turbo).
::
::  Description:
::    This script serves as the main entry point for environment activation
::    and dependency management. It guarantees that:
::      - cmd.exe Delayed Expansion is enabled
::      - The shell is free from preactivated Python/Conda contexts
::      - MS Build Tools are available and activated
::      - Required libraries are initialized via their respective scripts
::      - Proper INCLUDE, LIB, LINK, and PATH variables are configured
::      - Environment is ready for subsequent FFCV installation or builds
::
::  Invocation Modes:
::      /batch        - Activates environment variables only; does not launch
::                      FAR Manager or start a new interactive shell.
::
::      /preactivate  - Performs environment pre-initialization
::
::      (no argument) - Activates full environment and launches FAR Manager
::                      (if detected) or opens a regular cmd.exe session.
::
::  Behavioral Summary:
::      1. Verifies cmd.exe configuration and base environment cleanliness.
::      2. Activates MS Build Tools environment or notifies user of failure.
::      3. Ensures Conda (or Micromamba) environment readiness.
::      4. Sequentially activates pthreads, OpenCV, and libjpeg-turbo.
::      5. Updates INCLUDE, LIB, and LINK paths to integrate Conda libraries.
::      6. Exposes DISTUTILS_USE_SDK=1 to enable setuptools to reuse the
::         existing MSVC environment instead of launching new compiler shells.
::      7. Starts FAR Manager if available, or leaves the user in a prepared
::         cmd.exe session.
::
::  Exit Codes:
::      0   - Success
::      1+  - Failure during activation (refer to last console output)
::
::  Notes:
::      - Requires Windows 10+ with ANSI color output support.
::      - Requires curl.exe and tar.exe in PATH (included by default in Win10+).
::      - Colorized output can be disabled by defining NOCOLOR=1.
:: ============================================================================

echo:
echo ==========================================================================
echo %INFO% Setting up environment
echo %INFO%
echo %WARN% CLI: "%~f0" %*
echo ==========================================================================
echo:

set "EXIT_STATUS=1"

:: --- Escape sequence templates for color coded console output ---

call :COLOR_SCHEME

:: --- Default Conda Prefix ---

if defined _CONDA_PREFIX (
  set "__CONDA_PREFIX=%_CONDA_PREFIX%"
) else (
  set "__CONDA_PREFIX=%~dp0Anaconda"
)
set "CONDA_BAT=%__CONDA_PREFIX%\condabin\conda.bat"
set "MAMBA_BAT=%__CONDA_PREFIX%\condabin\mamba.bat"

:: --- Make sure cmd.exe delayed expansion is enabled by default ---

call :CHECK_DELAYED_EXPANSION
if not "%ERRORLEVEL%"=="0" if not "%~1"=="" (

  rem -- Delayed Expansion is disabled, running in non-interactive mode ---
  
  set "FINAL_EXIT_CODE=%ERRORLEVEL%"
  echo %ERROR% Delayed Expansion is disabled while running in non-interactive mode. Aborting...
  goto :CLEANUP
) else (

  rem --- Delayed Expansion is disabled, running in interactive mode ---
  
  setlocal EnableDelayedExpansion EnableExtensions
)

:: --- Determine cache directory ---

if not defined _CACHE (
  call :CACHE_DIR
  set "EXIT_STATUS=!ERRORLEVEL!"
) else (
  set "EXIT_STATUS=0"
)
if not defined _CACHE (
  echo %ERROR% Failed to set CACHE directory. Aborting...
  set "FINAL_EXIT_CODE=1"
  goto :CLEANUP
)
echo:

:: --- Base / Root environment guard ---

call :NO_ROOT_ENVIRONMENT
if not "%ERRORLEVEL%"=="0" (
  echo %ERROR% Aborting due to pre-existing Python/Conda environment.
  set "FINAL_EXIT_CODE=%ERRORLEVEL%"
  goto :CLEANUP
)

:: --- MS Build Tools ---

if not exist "%~dp0msbuild.bat" (
  echo %ERROR% MSBUILD activation script not found: "%~dp0msbuild.bat". Aborting...
  set "FINAL_EXIT_CODE=1"
  goto :CLEANUP
)
call "%~dp0msbuild.bat"
if not "%ERRORLEVEL%"=="0" (
  echo %ERROR% MSBuild activation failed. Aborting...
  set "FINAL_EXIT_CODE=1"
  goto :CLEANUP
)

:: --- Have Python/setuptools/distutils use preactivated MS Build Tools environment. ---

set "DISTUTILS_USE_SDK=1"

call :COLOR_SCHEME

:: --- Python.exe and conda.bat must exist in Conda environment ---

if not exist "%__CONDA_PREFIX%\python.exe" (
  echo %ERROR% Python not found: "%__CONDA_PREFIX%\python.exe". Aborting...
  set "FINAL_EXIT_CODE=1"
  goto :CLEANUP
)
if not exist "%CONDA_BAT%" (
  echo %ERROR% Conda activation script not found: "%CONDA_BAT%". Aborting...
  set "FINAL_EXIT_CODE=1"
  goto :CLEANUP
)
if not exist "%MAMBA_BAT%" (
  echo %ERROR% Conda activation script not found: "%MAMBA_BAT%". Aborting...
  set "FINAL_EXIT_CODE=1"
  goto :CLEANUP
)

:: --- Activate Conda environment ---

echo:
echo %WARN% Activating Conda PREFIX "%__CONDA_PREFIX%".
call "%CONDA_BAT%" activate
if not "%ERRORLEVEL%"=="0" (
  set "FINAL_EXIT_CODE=%ERRORLEVEL%"
  echo %ERROR% Conda environment activation failed. Aborting...
  goto :CLEANUP
)
if not exist "!CONDA_PREFIX!\python.exe" (
  echo %ERROR% Conda environment activation failed - Python "!CONDA_PREFIX!\python.exe" not found. Aborting...
  set "FINAL_EXIT_CODE=1"
  goto :CLEANUP
)
echo %OKOK% Conda activation succeeded.

:: --- Activate dependencies ---

if not exist "%~dp0libs.bat" (
  echo %ERROR% Library activation script not found: "%~dp0libs.bat". Aborting...
  set "FINAL_EXIT_CODE=1"
  goto :CLEANUP
)
if /I "%~1"=="/preactivate" (
  call "%~dp0libs.bat" /preactivate
  set "EXIT_STATUS=!ERRORLEVEL!"
) else (
  call "%~dp0libs.bat" /activate
  set "EXIT_STATUS=!ERRORLEVEL!"
)

call :COLOR_SCHEME

if "%EXIT_STATUS%"=="0" (
  echo %OKOK% Library activation complete.
  echo:
) else (
  echo %ERROR% Library activation failed. EXIT_STATUS: "%EXIT_STATUS%".
  echo:
  set "FINAL_EXIT_CODE=%EXIT_STATUS%"
  goto :CLEANUP
)

:: --- Use "/batch" to activate shell environment without starting FAR MANAGER ---

set "FINAL_EXIT_CODE=0"
if /I "%~1"=="/batch" goto :CLEANUP
if /I "%~1"=="/preactivate" goto :CLEANUP

:: --- Start FAR MANAGER ---

for %%A in ("far.bat" "far.exe") do (
  where /Q %%~A >nul 2>nul && (
    set "_FARMANAGER=%%~A"
    goto :START_FARMANAGER
  )
)

:START_FARMANAGER

if not defined _FARMANAGER set "_FARMANAGER=cd"
cmd /E:ON /V:ON /K "%_FARMANAGER% ""%__CONDA_PREFIX%"""
set "_FARMANAGER="

goto :CLEANUP
:: ============================================================================
:: ============================================================================
:: ============================================================================


:: ============================================================================ COLOR_SCHEME BEGIN
:: ============================================================================
:COLOR_SCHEME
:: ---------------------------------------------------------------------
:: Color Scheme (with NOCOLOR fallback)
:: ---------------------------------------------------------------------

if defined NOCOLOR (
  set  "INFO= [INFO]  "
  set  "OKOK= [-OK-]  "
  set  "WARN= [WARN]  "
  set "ERROR= [ERROR] "
) else (
  set  "INFO=[100;92m [INFO]  [0m"
  set  "OKOK=[103;94m [-OK-]  [0m"
  set  "WARN=[106;35m [WARN]  [0m"
  set "ERROR=[105;34m [ERROR] [0m"
)

exit /b 0
:: ============================================================================ 
:: ============================================================================ COLOR_SCHEME END


:: ============================================================================ CLEANUP BEGIN
:: ============================================================================
:: --- Clean up; prefer as the primary script exit point ---
:: To exit script, set FINAL_EXIT_CODE and goto CLEANUP

:CLEANUP

set  "INFO="
set  "OKOK="
set  "WARN="
set "ERROR="
set "EXIT_STATUS="
set "__CONDA_PREFIX="

:: --- Ensure a valid exit code is always returned ---

if not defined FINAL_EXIT_CODE set "FINAL_EXIT_CODE=1"
exit /b %FINAL_EXIT_CODE%
:: ============================================================================ 
:: ============================================================================ CLEANUP END


:: ============================================================================ CACHE_DIR BEGIN
:: ============================================================================
:CACHE_DIR
:: --------------------------------------------------------
:: Determine cache directory
:: --------------------------------------------------------
if exist "%_CACHE%" (
  goto :CACHE_DIR_SET
) else (
  set "_CACHE=%TEMP%"
)

if exist "%~d0\CACHE" (
  set "_CACHE=%~d0\CACHE"
  goto :CACHE_DIR_SET
)

if exist "%~dp0CACHE" (
  set "_CACHE=%~dp0CACHE"
  goto :CACHE_DIR_SET
)

if exist "%USERPROFILE%\Downloads" (
  if exist "%USERPROFILE%\Downloads\CACHE" (
    set "_CACHE=%USERPROFILE%\Downloads\CACHE"
  ) else (
    set "_CACHE=%USERPROFILE%\Downloads"
  )
  goto :CACHE_DIR_SET
)

:CACHE_DIR_SET
:: --------------------------------------------------------
:: Verify file system access
:: --------------------------------------------------------
set "_DUMMY=%_CACHE%\$$$_DELETEME_ACCESS_CHECK_$$$"
if exist "%_DUMMY%" rmdir /Q /S "%_DUMMY%"
set "EXIT_STATUS=%ERRORLEVEL%"
if exist "%_DUMMY%" set "EXIT_STATUS=1"
if not "!EXIT_STATUS!"=="0" (
  echo %ERROR% Failed to delete test directory "%_DUMMY%".
  echo %ERROR% Expected a full-access at this location "%_CACHE%".
  echo %ERROR% Aborting...
  set "_CACHE="
  exit /b !EXIT_STATUS!
)

md "%_DUMMY%"
set "EXIT_STATUS=%ERRORLEVEL%"
if not exist "%_DUMMY%" set "EXIT_STATUS=1"
if not "!EXIT_STATUS!"=="0" (
  echo %ERROR% Failed to create test directory "%_DUMMY%".
  echo %ERROR% Expected a full-access at this location "%_CACHE%".
  echo %ERROR% Aborting...
  set "_CACHE="
  exit /b !EXIT_STATUS!
)

:: --------------------------------------------------------
:: Point CONDA_PKGS_DIRS and PIP_CACHE_DIR to package cache directory
:: --------------------------------------------------------
set "_PKGS_DIR=%_CACHE%\Python\pkgs"

if not defined CONDA_PKGS_DIRS (
  set "CONDA_PKGS_DIRS=%_PKGS_DIR%"
) else (
  set "_PKGS_DIR=%CONDA_PKGS_DIRS%"
)
if not exist "%CONDA_PKGS_DIRS%" md "%CONDA_PKGS_DIRS%"
if not "%ERRORLEVEL%"=="0" (
  echo %ERROR% Failed to create directory "%CONDA_PKGS_DIRS%".
  set "_CACHE="
  exit /b !EXIT_STATUS!
)
set "PIP_CACHE_DIR=%_CACHE%\Python\pip"

echo %INFO% CACHE directory: "%_CACHE%".
echo %INFO% CONDA_PKGS_DIRS directory: "%CONDA_PKGS_DIRS%".
echo %INFO% PIP_CACHE_DIR   directory: "%PIP_CACHE_DIR%".

exit /b 0
:: ============================================================================
:: ============================================================================ CACHE_DIR END


:: ============================================================================ CHECK_DELAYED_EXPANSION BEGIN
:: ============================================================================
:CHECK_DELAYED_EXPANSION
::
:: Purpose:
::   Checks if Delayed Expansion is enabled.
::
:: Return:
::   DELAYED_EXPANSION=1 - Enabled
::   DELAYED_EXPANSION=0 - Disabled
::
:: Exit Codes:
::   0 - Enabled
::   1 - Disabled

echo:
echo %WARN% Checking cmd.exe delayed expansion availability
echo %INFO%
echo %INFO% When running with any arguments, Delayed Expansion feature must be
echo %INFO% enabled by the caller!
echo %INFO% When running withhout arguments, the script is supposed to spawn
echo %INFO% an activated shell, so Delayed Expansion can be enabled locally.

if "!ComSpec!"=="%ComSpec%" (
  set "DELAYED_EXPANSION=1"
  echo %INFO% --------------------------
  echo %OKOK% CHECK PASSED
  echo %INFO% Delayed Expansion enabled.
  echo %INFO% --------------------------
  echo:
  exit /b 0
) else (
  set "DELAYED_EXPANSION=0"
)

echo:
echo %INFO% ------------------------------------------------------------------------
echo %ERROR% CHECK FAILED
echo %WARN% Delayed Expansion disabled.
echo %INFO% This script should be generally called with Delayed Expansion enabled
echo %INFO% by the caller. When used interactively without any arguments, this 
echo %INFO% script will activate Conda environment aand spawn an activated shell.
echo %INFO% In this mode, Delayed Expansion mode can be activated by this script.
echo %INFO% In batch mode, this script is used to activate caller's environment,
echo %INFO% and, therefore this script will be unable to activate both Delayed
echo %INFO% Expansion and the caller's environment. Use one of the following
echo %INFO% options, then rerun this script with "/batch" switch to verify that the
echo %INFO% test passes.
echo %INFO% 
echo %INFO% 1. "setlocal EnableDelayedExpansion EnableExtensions"
echo %INFO%    Use this command in the parent script before calling this script.
echo %INFO%    
echo %INFO% 2. Start a new cmd.exe shell as "cmd.exe /E:ON /V:ON".
echo %INFO% 
echo %INFO% 3. Enable Delayed Expansion permanently via the following registry
echo %INFO%    setting (either variant should do), start a new shell, 
echo %INFO% ------------------------------------------------------------------------
echo: 
echo %INFO% Delayed expansion activation settings. 
echo: 
echo %INFO% ------------------------------------------------------------------------
echo %INFO% [HKEY_CURRENT_USER\Software\Microsoft\Command Processor]
echo %INFO% "DelayedExpansion"=dword:00000001
echo %INFO% "EnableExtensions"=dword:00000001
echo %INFO% 
echo %INFO% --- OR ---
echo %INFO% 
echo %INFO% [HKEY_LOCAL_MACHINE\Software\Microsoft\Command Processor]
echo %INFO% "DelayedExpansion"=dword:00000001
echo %INFO% "EnableExtensions"=dword:00000001
echo %INFO% ------------------------------------------------------------------------
echo:

exit /b 1
:: ============================================================================ 
:: ============================================================================ CHECK_DELAYED_EXPANSION END


:: ============================================================================ NO_ROOT_ENVIRONMENT BEGIN
:: ============================================================================
:: --------------------------------------------------------
:: NO_ROOT_ENVIRONMENT
::
:: This script should not be executed from a shell with active Python / Conda 
:: environment (visible conda.bat or python.exe). If found, issue a warning and
:: attempt to deactivate. Note, if active Python envirnoment was activated via
:: `conda activate` is should be possible to deactivate it via `conda deactivate`
:: If Python was placed on Path via Conda activation, deactivation should
:: remove it from Path. However, if Python is placed on Path independently,
:: for example via system-wide installation, deactivation will likely fail to
:: remove Python from Path. ALSO, if custom activation wrapper was used, such
:: as this very script, deactivation will not remove any custom envirnoment
:: settings. In such a case, effectively partial deactivation may result in
:: issues, potentially subtle, in the new environment. In particular, this
:: script activates external build dependencies for FFCV, and associated
:: settings may result in wrong dependency references and failed builds, if
:: new environment is not started from a clean system shell.
:: --------------------------------------------------------
:NO_ROOT_ENVIRONMENT

echo:
echo ====================================================================================
echo ====================================================================================
echo == %WARN%                                                            %WARN% ==
echo == %WARN%         Checking for activated Conda environment           %WARN% ==
echo == %WARN%                                                            %WARN% ==
echo ====================================================================================
echo ====================================================================================
echo:

:: --- Check if Conda or Python is on the Path ---

set "_CONDA="
set "_PYTHON="
echo %INFO% Checking if Python on the Path
where "python.exe" 2>nul && (set "_PYTHON=python.exe")
echo %INFO% Checking if Conda on the Path
where "conda.bat" 2>nul && (set "_CONDA=conda.bat")
if not defined _CONDA if not defined _PYTHON (
  echo %OKOK% Python/Conda not detected.
  set "_CONDA="
  set "_PYTHON="
  exit /b 0
)

echo:
if defined _PYTHON (
  echo %WARN% Detected "python.exe" in Path.
)
if defined _CONDA (
  echo %WARN% Detected "conda.bat" in Path.
)

echo %WARN% It is strongly recommended to start this script from a clean
echo %WARN% environment. No Conda or Python variables should be in Path.

exit /b 1
:: ============================================================================ 
:: ============================================================================ NO_ROOT_ENVIRONMENT END
```

---
`AIFFCV/libs.bat`

```
@echo off

:: ============================================================================
::  Purpose:
::    Downloads and extracts pthreads and OpenCV native libraries.
::    Activates environment settings for:
::      pthreads, OpenCV, LibJPEG-Turbo
::    (LibJPEG-Turbo is assumed to be installed via a Conda package).
::    Supports caching for large downloads (OpenCV).
::
::  Invocation Modes:
::      /preactivate  - Performs environment pre-initialization
::                      (ignore missing files).
::
::      /activate     - Performs environment initialization.
::
::      /install      - Copies DLL to CONDA_PREFIX.
::
::      (no argument) - Downloads and prepares libraries.
::
::  Notes:
::    - CRITICAL: This script MUST be called by a parent script
::      that has enabled delayed expansion (e.g., SETLOCAL EnableDelayedExpansion).
::
::    - CRITICAL: This script and its sub-scripts modify the caller's
::      environment. They CANNOT use SETLOCAL internally.
::
::    - Requires curl.exe and tar.exe (included in modern Windows 10).
::
::    - Uses color-coded output with ANSI escapes when available.
::      To disable colors, set NOCOLOR=1 before calling this script.
::
::    - No verification of downloads or extracted, possibly partially, files.
::      The script uses download caching, but does not handle interrupted partial
::      downloads. If interrupted, the script will attempt to use defective
::      downloaded file, most likely causing subsequent unconditional extraction
::      failure. If such an error occurs, manually delete defective files, which
::      should be indicated in the error message; then rerun the script.
:: ============================================================================

set "EXIT_STATUS="

:: --- Escape sequence templates for color coded console output ---

call :COLOR_SCHEME

echo:
echo ====================================================================================
echo ====================================================================================
echo == %WARN%                                                            %WARN% ==
echo == %WARN%                    Managing libraries                      %WARN% ==
echo == %WARN%                                                            %WARN% ==
echo == %WARN% CLI: "%~f0" %*
echo ====================================================================================
echo ====================================================================================
echo:

:: --------------------------------------------------------
:: Check for activation
:: --------------------------------------------------------
for %%A in ("/activate" "/preactivate") do (
  if /I "%~1"=="%%~A" goto :ACTIVATE
)

:: --------------------------------------------------------
:: Check for installation
:: --------------------------------------------------------

for %%A in ("/i" "/install") do (
  if /I "%~1"=="%%~A" goto :INSTALL
)

echo:
echo ====================================================================================
echo ====================================================================================
echo == %WARN%                                                            %WARN% ==
echo == %WARN%           Installing libraries - Default location          %WARN% ==
echo == %WARN%                                                            %WARN% ==
echo == %WARN% CLI: "%~f0" %*
echo ====================================================================================
echo ====================================================================================
echo:

:: --------------------------------------------------------
:: Determine cache directory
:: --------------------------------------------------------
set "EXIT_STATUS=0"
if not defined _CACHE call :CACHE_DIR
if not "%ERRORLEVEL%"=="0" set "_CACHE="
if not defined _CACHE (
  echo %ERROR% Failed to set CACHE directory. Aborting...
  set "FINAL_EXIT_CODE=1"
  goto :CLEANUP
)
echo:

:: --------------------------------------------------------
:: Verify availability of curl and tar.
:: --------------------------------------------------------
for %%A in ("curl.exe" "tar.exe") do (
  where %%~A >nul 2>nul || (
    echo %ERROR% "%%~A" not found.
    set "FINAL_EXIT_CODE=1"
    goto :CLEANUP
  )
)

:: --------------------------------------------------------
:: pthreads
:: --------------------------------------------------------
call :PTHREADS_DOWNLOAD
set "FINAL_EXIT_CODE=%ERRORLEVEL%"
if not "%FINAL_EXIT_CODE%"=="0" goto :CLEANUP

:: --------------------------------------------------------
:: OpenCV
:: --------------------------------------------------------
call :OPENCV_DOWNLOAD
set "FINAL_EXIT_CODE=%ERRORLEVEL%"
goto :CLEANUP

:: ============================================================================
:: ============================================================================
:: ============================================================================


:: ============================================================================ ACTIVATE BEGIN
:: ============================================================================
:: ============================================================================
:ACTIVATE

echo:
echo ====================================================================================
echo ====================================================================================
echo == %WARN%                                                            %WARN% ==
echo == %WARN%                    Activating libraries                    %WARN% ==
echo == %WARN%                                                            %WARN% ==
echo == %WARN% CLI: "%~f0" %*
echo ====================================================================================
echo ====================================================================================
echo:

if /I "%~1"=="/preactivate" (
  set "_MODE=/f"
) else (
  set "_MODE="
)
set "EXIT_STATUS=1"
set "TOTAL_ERRORS=0"

:::: --- Conda Environment Activation Settings for %CONDA_PREFIX%\Library ---
::
:::: --- Update INCLUDE if new item has not been added before ---
::
::set "_INCPATH=%__CONDA_PREFIX%\Library\include"
::if "!INCLUDE!"=="!INCLUDE:%_INCPATH%=!" (
::  set "INCLUDE=%_INCPATH%;%INCLUDE%"
::) else (
::  echo %INFO% "%_INCPATH%" already added to %%INCLUDE%%
::)
::set "_INCPATH="
::
:: --- Update LIB if new item has not been added before ---
::
::set "_LIBPATH=%__CONDA_PREFIX%\Library\lib"
::if "!LIB!"=="!LIB:%_LIBPATH%=!" (
::  set "LIB=%_LIBPATH%;%LIB%"
::) else (
::  echo %INFO% "%_LIBPATH%" already added to %%LIB%%
::)
::set "_LIBPATH="

:: --- pthreads ---

if exist "%~dp0pthreads\activate.bat" (
  echo:
  echo %WARN% Activating pthreads library.
  call "%~dp0pthreads\activate.bat" %_MODE%
  set "EXIT_STATUS=!ERRORLEVEL!"
  call :COLOR_SCHEME
) else (
  echo %ERROR% pthreads activation script not found: "%~dp0pthreads\activate.bat".
  set "EXIT_STATUS=1"
)
if not "%EXIT_STATUS%"=="0" (
  echo %ERROR% pthreads activation failed.
) else (
  echo %OKOK% pthreads activation succeeded.
)
set /a "TOTAL_ERRORS+=%EXIT_STATUS%"

:: --- OpenCV ---

if exist "%~dp0opencv\activate.bat" (
  echo:
  echo %WARN% Activating OpenCV library.
  call  "%~dp0opencv\activate.bat" %_MODE%
  set "EXIT_STATUS=!ERRORLEVEL!"
  call :COLOR_SCHEME
) else (
  echo %WARN% OpenCV activation script not found: "%~dp0opencv\activate.bat".
  set "EXIT_STATUS=1"
)
if not "%EXIT_STATUS%"=="0" (
  echo %ERROR% OpenCV activation failed.
) else (
  echo %OKOK% OpenCV activation succeeded.
)
set /a "TOTAL_ERRORS+=%EXIT_STATUS%"

:: --- LibJPEG-Turbo ---

if exist "%~dp0libjpeg-turbo\activate.bat" (
  echo:
  echo %WARN% Activating LibJPEG-Turbo library.
  call "%~dp0libjpeg-turbo\activate.bat" %_MODE%
  set "EXIT_STATUS=!ERRORLEVEL!"
  call :COLOR_SCHEME
) else (
  echo %ERROR% LibJPEG-Turbo activation script not found: "%~dp0libjpeg-turbo\activate.bat".
  set "EXIT_STATUS=1"
)
if not "%EXIT_STATUS%"=="0" (
  echo %ERROR% LibJPEG-Turbo activation failed.
) else (
  echo %OKOK% LibJPEG-Turbo activation succeeded.
)
set /a "TOTAL_ERRORS+=%EXIT_STATUS%"
echo ==========================================================================
echo:

if /I "%_MODE%"=="/f" (
  echo:
  rem                   ----- Mon 10/20/2025 21:03:09.88 -----
  echo:                 ----- %DATE% %TIME% -----
  echo ====================================================================================
  echo ====================================================================================
  echo == %WARN%                                                            %WARN% ==
  echo == %WARN%      File not found errors related to library modules      %WARN% ==
  echo == %WARN%      reported during installation above are expected.      %WARN% ==
  echo == %WARN%                                                            %WARN% ==
  echo ====================================================================================
  echo ====================================================================================
  echo:
)

set "FINAL_EXIT_CODE=%TOTAL_ERRORS%"
goto :CLEANUP
:: ============================================================================
:: ============================================================================
:: ============================================================================ ACTIVATE END


:: ============================================================================ INSTALL BEGIN
:: ============================================================================
:: ============================================================================
:INSTALL

echo:
echo ====================================================================================
echo ====================================================================================
echo == %WARN%                                                            %WARN% ==
echo == %WARN%              Installing libraries to CONDA_PREFIX          %WARN% ==
echo == %WARN%                                                            %WARN% ==
echo == %WARN% CLI: "%~f0" %*
echo ====================================================================================
echo ====================================================================================
echo:

set "EXIT_STATUS=0"

:: --- pthreads ---

if exist "%~dp0pthreads\activate.bat" (
  echo:
  echo %WARN% Installing pthreads library.
  call "%~dp0pthreads\activate.bat" /i
  set "EXIT_STATUS=!ERRORLEVEL!"
  call :COLOR_SCHEME
) else (
  echo %ERROR% pthreads activation script not found: "%~dp0pthreads\activate.bat".
  set "EXIT_STATUS=1"
)
if not "%EXIT_STATUS%"=="0" (
  echo %ERROR% pthreads installation failed.
  exit /b %EXIT_STATUS%
) else (
  echo %OKOK% pthreads installation succeeded.
)

:: --- OpenCV ---

if exist "%~dp0opencv\activate.bat" (
  echo:
  echo %WARN% Installing OpenCV library.
  call  "%~dp0opencv\activate.bat" /i
  set "EXIT_STATUS=!ERRORLEVEL!"
  call :COLOR_SCHEME
) else (
  echo %WARN% OpenCV activation script not found: "%~dp0opencv\activate.bat".
  set "EXIT_STATUS=1"
)
if not "%EXIT_STATUS%"=="0" (
  echo %ERROR% OpenCV installation failed.
  exit /b %EXIT_STATUS%
) else (
  echo %OKOK% OpenCV installation succeeded.
)

:: --- LibJPEG-Turbo ---

if exist "%~dp0libjpeg-turbo\activate.bat" (
  echo:
  echo %WARN% Installing LibJPEG-Turbo library.
  call "%~dp0libjpeg-turbo\activate.bat" /i
  set "EXIT_STATUS=!ERRORLEVEL!"
  call :COLOR_SCHEME
) else (
  echo %ERROR% LibJPEG-Turbo activation script not found: "%~dp0libjpeg-turbo\activate.bat".
  set "EXIT_STATUS=1"
)
if not "%EXIT_STATUS%"=="0" (
  echo %ERROR% LibJPEG-Turbo installation failed.
  exit /b %EXIT_STATUS%
) else (
  echo %OKOK% LibJPEG-Turbo installation succeeded.
)

echo ==========================================================================
echo:

set "FINAL_EXIT_CODE=%EXIT_STATUS%"
goto :CLEANUP
:: ============================================================================
:: ============================================================================
:: ============================================================================ INSTALL END


:: ============================================================================ CLEANUP BEGIN
:: ============================================================================
:CLEANUP

set "INFO="
set "OKOK="
set "WARN="
set "ERROR="
set "EXIT_STATUS="
set "TOTAL_ERRORS="
set "_MODE="

set "_DUMMY="
set "RELEASE_URL="
set "PREFIX="
set "_CD="
set "PTHREADS_ZIP="
set "OPENCV_SFX="
set "PTHREADS_ZIP_PARTIAL="
set "OPENCV_SFX_PARTIAL="

if not defined FINAL_EXIT_CODE set "FINAL_EXIT_CODE=1"
exit /b %FINAL_EXIT_CODE%
:: ============================================================================
:: ============================================================================ CLEANUP END


:: ============================================================================ COLOR_SCHEME BEGIN
:: ============================================================================
:COLOR_SCHEME
:: ---------------------------------------------------------------------
:: Color Scheme (with NOCOLOR fallback)
:: ---------------------------------------------------------------------

if defined NOCOLOR (
  set  "INFO= [INFO]  "
  set  "OKOK= [-OK-]  "
  set  "WARN= [WARN]  "
  set "ERROR= [ERROR] "
) else (
  set  "INFO=[100;92m [INFO]  [0m"
  set  "OKOK=[103;94m [-OK-]  [0m"
  set  "WARN=[106;35m [WARN]  [0m"
  set "ERROR=[105;34m [ERROR] [0m"
)

exit /b 0
:: ============================================================================ 
:: ============================================================================ COLOR_SCHEME END


:: ============================================================================ CACHE_DIR BEGIN
:: ============================================================================
:CACHE_DIR
:: --------------------------------------------------------
:: Determine cache directory
:: --------------------------------------------------------
if exist "%_CACHE%" goto :CACHE_DIR_SET
set "_CACHE=%TEMP%"

if exist "%~d0\CACHE" (
  set "_CACHE=%~d0\CACHE"
  goto :CACHE_DIR_SET
)

if exist "%~dp0CACHE" (
  set "_CACHE=%~dp0CACHE"
  goto :CACHE_DIR_SET
)

if exist "%USERPROFILE%\Downloads" (
  if exist "%USERPROFILE%\Downloads\CACHE" (
    set "_CACHE=%USERPROFILE%\Downloads\CACHE"
  ) else (
    set "_CACHE=%USERPROFILE%\Downloads"
  )
  goto :CACHE_DIR_SET
)

:CACHE_DIR_SET
:: --------------------------------------------------------
:: Verify file system access
:: --------------------------------------------------------
set "_DUMMY=%_CACHE%\$$$_DELETEME_ACCESS_CHECK_$$$"
if exist "%_DUMMY%" rmdir /Q /S "%_DUMMY%"
set "EXIT_STATUS=%ERRORLEVEL%"
if exist "%_DUMMY%" set "EXIT_STATUS=1"
if not "%EXIT_STATUS%"=="0" (
  echo %ERROR% Failed to delete test directory "%_DUMMY%".
  echo %ERROR% Expected a full-access at this location "%_CACHE%".
  echo %ERROR% Aborting...
  set "_CACHE="
  exit /b %EXIT_STATUS%
)

md "%_DUMMY%"
set "EXIT_STATUS=%ERRORLEVEL%"
if not exist "%_DUMMY%" set "EXIT_STATUS=1"
if not "%EXIT_STATUS%"=="0" (
  echo %ERROR% Failed to create test directory "%_DUMMY%".
  echo %ERROR% Expected a full-access at this location "%_CACHE%".
  echo %ERROR% Aborting...
  set "_CACHE="
  exit /b %EXIT_STATUS%
)

exit /b 0
:: ============================================================================
:: ============================================================================ CACHE_DIR END


:: ============================================================================ PTHREADS_DOWNLOAD BEGIN
:: ============================================================================
:PTHREADS_DOWNLOAD

echo %WARN% pthreads
:: --------------------------------------------------------
:: Download pthreads
:: --------------------------------------------------------
set "RELEASE_URL=ftp://sourceware.org/pub/pthreads-win32/pthreads-w32-2-9-1-release.zip"
set "PREFIX=%_CACHE%\pthreads"
set "PTHREADS_ZIP=%PREFIX%\pthreads-w32-2-9-1-release.zip"

if not exist "%PREFIX%" md "%PREFIX%"
if not "%ERRORLEVEL%"=="0" (
  echo %ERROR% pthreads: Failed to create "%PREFIX%". Aborting bootstrapping...
)

if exist "%PTHREADS_ZIP%" (
  echo %INFO% pthreads: Using cached "%PTHREADS_ZIP%"
) else (
  echo %INFO% pthreads: Downloading: "%RELEASE_URL%"
  echo %INFO% pthreads: Destination: "%PTHREADS_ZIP%"

  rem --- Download to .part file ---

  set "PTHREADS_ZIP_PARTIAL=%PTHREADS_ZIP%.part"
  curl --fail --retry 3 --retry-delay 2 -L -o "!PTHREADS_ZIP_PARTIAL!" "%RELEASE_URL%"
  set "EXIT_STATUS=!ERRORLEVEL!"
  if not "!EXIT_STATUS!"=="0" (
    echo %ERROR% pthreads: Download failure. Aborting bootstrapping...
    exit /b !EXIT_STATUS!
  )

  rem -- On success, rename to final file ---

  move /Y "!PTHREADS_ZIP_PARTIAL!" "%PTHREADS_ZIP%" >nul
  if not "!ERRORLEVEL!"=="0" (
    echo %ERROR% pthreads: Failed to rename "%PTHREADS_ZIP%". Aborting bootstrapping...
    exit /b !ERRORLEVEL!
  )
)
set "PTHREADS_ZIP_PARTIAL="
set "RELEASE_URL="

:: --------------------------------------------------------
:: Extract pthreads
:: --------------------------------------------------------
echo %INFO% pthreads: Extracting "%PTHREADS_ZIP%".
set "_CD=%CD%"
cd /d "%PREFIX%"
tar -xf "%PTHREADS_ZIP%"
set "EXIT_STATUS=%ERRORLEVEL%"
cd /d "%_CD%"
set "_CD="
if not "%EXIT_STATUS%"=="0" (
  echo %ERROR% pthreads: Extraction failure - "%PTHREADS_ZIP%". Error - "%EXIT_STATUS%".
  echo %ERROR% pthreads: The error may be due to corrupted cached files due to previously
  echo %ERROR% pthreads: interrupted downloads. Try manually deleting "%PTHREADS_ZIP%"
  echo %ERROR% pthreads: and run the script again.
  exit /b %EXIT_STATUS%
) else (
  echo %INFO% pthreads: Extracted from "%PTHREADS_ZIP%".
)

xcopy /H /Y /B /E /Q "%PREFIX%\Pre-built.2\*.*" "%~dp0pthreads" 1>nul
set "EXIT_STATUS=%ERRORLEVEL%"
if not "%EXIT_STATUS%"=="0" (
  echo %ERROR% pthreads: Move failure - "%PREFIX%\Pre-built.2".
  exit /b %EXIT_STATUS%
) else (
  echo %INFO% pthreads: Moved from "%PREFIX%\Pre-built.2".
)

xcopy /H /Y /B /E /Q "%~dp0patched\pthread.h" "%~dp0pthreads\include" 1>nul
set "EXIT_STATUS=%ERRORLEVEL%"
if not "%EXIT_STATUS%"=="0" (
  echo %ERROR% pthreads: Move failure - "%~dp0patched\pthread.h".
  exit /b %EXIT_STATUS%
) else (
  echo %INFO% pthreads: Moved from "%~dp0patched\pthread.h".
)

echo %OKOK% pthreads: Completed.
echo:

exit /b 0
:: ============================================================================
:: ============================================================================ PTHREADS_DOWNLOAD END


:: ============================================================================ OPENCV_DOWNLOAD BEGIN
:: ============================================================================
:OPENCV_DOWNLOAD

echo %WARN% OpenCV
:: --------------------------------------------------------
:: Download OpenCV
:: --------------------------------------------------------
set "RELEASE_URL=https://github.com/opencv/opencv/releases/download/4.6.0/opencv-4.6.0-vc14_vc15.exe"
set "PREFIX=%_CACHE%\OpenCV"
set "OPENCV_SFX=%_CACHE%\OpenCV\opencv-4.6.0-vc14_vc15.exe"

if not exist "%PREFIX%" md "%PREFIX%"
if not "%ERRORLEVEL%"=="0" (
  echo %ERROR% OpenCV: Failed to create "%PREFIX%". Aborting bootstrapping...
)

if exist "%OPENCV_SFX%" (
  echo %INFO% OpenCV: Using cached "%OPENCV_SFX%"
) else (
  echo %INFO% OpenCV: Downloading: "%RELEASE_URL%"
  echo %INFO% OpenCV: Destination: "%OPENCV_SFX%"

  rem --- Download to .part file ---

  set "OPENCV_SFX_PARTIAL=%OPENCV_SFX%.part"
  curl --fail --retry 3 --retry-delay 2 -L -o "!OPENCV_SFX_PARTIAL!" "%RELEASE_URL%"
  set "EXIT_STATUS=!ERRORLEVEL!"
  if not "!EXIT_STATUS!"=="0" (
    echo %ERROR% OpenCV: Download failure. Aborting bootstrapping...
    exit /b !EXIT_STATUS!
  )

  rem -- On success, rename to final file ---

  move /Y "!OPENCV_SFX_PARTIAL!" "%OPENCV_SFX%" >nul
  if not "!ERRORLEVEL!"=="0" (
    echo %ERROR% OpenCV: Failed to rename "%OPENCV_SFX%". Aborting bootstrapping...
    exit /b !ERRORLEVEL!
  )
)
set "OPENCV_SFX_PARTIAL="
set "RELEASE_URL="

:: --------------------------------------------------------
:: Extract OpenCV
:: --------------------------------------------------------

if exist "%PREFIX%\$$EXTRACTED$$" (
  echo %INFO% OpenCV: Using extracted "%OPENCV_SFX%".
  goto :SKIP_OPENCV_EXTRACT
)
echo %INFO% OpenCV: Extracting "%OPENCV_SFX%".
"%OPENCV_SFX%" -y  -o"%PREFIX%"
set "EXIT_STATUS=!ERRORLEVEL!"
if not "%EXIT_STATUS%"=="0" (
  echo %ERROR% OpenCV: Extraction failure - "%OPENCV_SFX%".
  echo %ERROR% OpenCV: The error may be due to corrupted cached files due to previously
  echo %ERROR% OpenCV: interrupted downloads. Try manually deleting "%OPENCV_SFX%"
  echo %ERROR% OpenCV: and run the script again.
  exit /b %EXIT_STATUS%
) else (
  echo: >"%PREFIX%\$$EXTRACTED$$"
  echo %INFO% OpenCV: Extracted from "%OPENCV_SFX%".
)

:SKIP_OPENCV_EXTRACT

xcopy /H /Y /B /E /Q /I "%PREFIX%\opencv\build" "%~dp0opencv\build" 1>nul
set "EXIT_STATUS=!ERRORLEVEL!"
if not "%EXIT_STATUS%"=="0" (
  echo %ERROR% OpenCV: Move failure - "%PREFIX%\opencv\build".
  exit /b %EXIT_STATUS%
) else (
  echo %INFO% OpenCV: Moved from "%PREFIX%\opencv\build".
)

echo %OKOK% OpenCV: Completed.
echo:

exit /b 0
:: ============================================================================
:: ============================================================================ OPENCV_DOWNLOAD END
```

---
`AIFFCV/msbuild.bat`

```
@echo off

:: ============================================================================
::  Purpose:
::    Detects and activates Microsoft Build Tools (MSVC) environment if needed.
::    This script is idempotent and can be safely re-run.
::
::  Behavior:
::    - If MS Build Tools already active (VSINSTALLDIR set), exits successfully.
::    - Otherwise, searches standard and custom installation paths.
::    - Activates 64-bit environment via vcvars64.bat when found.
::
::  Preconditions:
::    - The CALLER's environment must have delayed expansion enabled
::      *prior* to calling this script.
::    - NOCOLOR: If set, gracefully falls back to no color.
::
::  Exit codes:
::    0 = success
::    1 = activation failed or not found
:: ============================================================================

:: --- Escape sequence templates for color coded console output ---

call :COLOR_SCHEME

:: --- MS Build Tools environment is activated? ---
::
:: Assume that activated shell must have variable VSINSTALLDIR set and
:: main activation script present in
:: "%VSINSTALLDIR%\VC\Auxiliary\Build\vcvarsall.bat"

echo:
echo ====================================================================================
echo ====================================================================================
echo == %WARN%                                                            %WARN% ==
echo == %WARN%                    MS Build Tools Check                    %WARN% ==
echo == %WARN%                                                            %WARN% ==
echo == %WARN% CLI: "%~f0" %*
echo ====================================================================================
echo ====================================================================================
echo:

set "EXIT_STATUS=1"

:: --- Check if already activated ---

echo %INFO% MSBuild: Checking if already activated...
set "_VCVARS=%VSINSTALLDIR%\VC\Auxiliary\Build\vcvarsall.bat"
if defined VSINSTALLDIR if exist "%_VCVARS%" (
  echo %INFO% MSBuild: VSINSTALLDIR points to "%VSINSTALLDIR%".
  echo %OKOK% MSBuild: Environment already active. Skipping activation.
  set "EXIT_STATUS=0"
  goto :MSBUILD_ACTIVATED
)

:: --- Check for default locations of VS 2022 editions  ---

for %%E in (BuildTools Community Professional Enterprise) do (
  set "_VCVARS=%ProgramFiles%\Microsoft Visual Studio\2022\%%E\VC\Auxiliary\Build\vcvarsall.bat"
  if exist "%_VCVARS%" goto :MSBUILD_ACTIVATION
)

:: --- Check if VCVARS is defined ---

echo %INFO% MSBuild: Checking if VCVARS points to vcvarsall.bat.
if defined VCVARS if exist "%VCVARS%" (
  set "_VCVARS=%VCVARS%"
  echo %INFO% MSBuild: VCVARS points to "%VCVARS%". Attempting activation...
  goto :MSBUILD_ACTIVATION
)

:: --- vcvarsall.bat on the PATH? ---

echo %INFO% MSBuild: Checking if vcvarsall.bat is on the PATH.
set "_VCVARS="
for /f "usebackq tokens=* delims=" %%A in (`where vcvarsall.bat 2^>nul`) do (
  if exist "%%~A" (
    set "_VCVARS=%%~A"
    echo %INFO% MSBuild: Found vcvarsall.bat on the PATH: "!_VCVARS!". Attempting activation...
    goto :MSBUILD_ACTIVATION
  )
)

:: --- BuildTools or its parent on the PATH? ---
::
:: If BuildTools are in
::   "C:\Program Files\Microsoft Visual Studio\2022\BuildTools"
:: and the main BuildTools environment setting script in 
::   "C:\Program Files\Microsoft Visual Studio\2022\BuildTools\VC\Auxiliary\Build\vcvarsall.bat",
:: add either
::   "C:\Program Files\Microsoft Visual Studio\2022"
::   "C:\Program Files\Microsoft Visual Studio\2022\BuildTools"
:: to the PATH.

echo %INFO% MSBuild: Checking if "BuildTools" or its parent are on the PATH.
set "_PATH=%Path:"=%"
set "_PATH="%_PATH:;=";"%""

:: Iterates over individual PATH components.

for %%A in (%_PATH%) do (
  set "_VCVARS=%%~A\VC\Auxiliary\Build\vcvarsall.bat"
  if exist "%_VCVARS%" goto :MSBUILD_ACTIVATION
  set "_VCVARS=%%~A\BuildTools\VC\Auxiliary\Build\vcvarsall.bat"
  if exist "%_VCVARS%" goto :MSBUILD_ACTIVATION
)
set "_VCVARS="
set "_PATH="

:: --- Check custom env variables ---
::
:: Set either BUILDTOOLS or MSBUILDTOOLS to point to BuildTools (same as VSINSTALLDIR after
:: MS Build Tools environment is activated), i.e., main script should be
::   %BUILDTOOLS%\VC\Auxiliary\Build\vcvarsall.bat%

echo %INFO% MSBuild: Checking if BUILDTOOLS or MSBUILDTOOLS point to the "BuildTools" directory.
set "_VCVARS=%BUILDTOOLS%\VC\Auxiliary\Build\vcvarsall.bat"
if exist "%_VCVARS%" goto :MSBUILD_ACTIVATION
set "_VCVARS=%MSBUILDTOOLS%\VC\Auxiliary\Build\vcvarsall.bat"
if exist "%_VCVARS%" goto :MSBUILD_ACTIVATION

:: --- Directory junction MSBuildTools or BuildTools fallback ---
::
:: This script's project might be placed under some "dev" directory also containing
:: directory junction, pointing to MSVS BuildTools directory (see above) called either
::   BuildTools
::   MSBuildTools
:: Final check - the same directory junction might be under "dev" directory
:: created in the root of the current drive.

echo %INFO% MSBuild: Checking custom fallback locations for BuildTools.
set "_VCVARS=%~dp0..\MSBuildTools\VC\Auxiliary\Build\vcvarsall.bat"
if exist "%_VCVARS%" goto :MSBUILD_ACTIVATION
set "_VCVARS=%~dp0..\BuildTools\VC\Auxiliary\Build\vcvarsall.bat"
if exist "%_VCVARS%" goto :MSBUILD_ACTIVATION
set "_VCVARS=%~d0\dev\MSBuildTools\VC\Auxiliary\Build\vcvarsall.bat"
if exist "%_VCVARS%" goto :MSBUILD_ACTIVATION
set "_VCVARS=%~d0\dev\BuildTools\VC\Auxiliary\Build\vcvarsall.bat"
if exist "%_VCVARS%" goto :MSBUILD_ACTIVATION

:: --- MSBuildTools not found ---

set "EXIT_STATUS=1"
echo %ERROR% MSBuild: MS Build Tools activation script not found.
echo %INFO% MSBuild: If MS Build Tools are installed, either
echo %INFO% MSBuild:   - start this script from a preactivated MS Build Tools shell
echo %INFO% MSBuild:   - see script notes above regarding checked locations and variables
echo %INFO% MSBuild: See this accepted SO answer https://stackoverflow.com/a/64262038/17472988
echo %INFO% MSBuild: regarding MS Build Tools installation.
echo:
echo %ERROR% MSBuild: FFCV will not get installed without compiler.
goto :MSBUILD_ACTIVATED

:MSBUILD_ACTIVATION

::--- MSBuildTools found ---

if not exist "%_VCVARS:all.bat=64.bat%" (
  echo %ERROR% MSBuild: 64-bit activation script not found at "%_VCVARS:all.bat=64.bat%".
  set "EXIT_STATUS=1"
  goto :MSBUILD_ACTIVATED
)

echo:
echo %WARN% MSBuild: Activating MS Build Tools.
echo %INFO% MSBuild: Calling "%_VCVARS:all.bat=64.bat%"
echo:
call "%_VCVARS:all.bat=64.bat%"
set "EXIT_STATUS=%ERRORLEVEL%"
echo:
if not "%EXIT_STATUS%"=="0" (
  echo %ERROR% MSBuild: vcvars64.bat returned an error.
  set "EXIT_STATUS=1"
  goto :MSBUILD_ACTIVATED
)

if not defined VSINSTALLDIR (
  echo %ERROR% MSBuild: Activation returned success, but VSINSTALLDIR is missing. Aborting...
  set "EXIT_STATUS=1"
  goto :MSBUILD_ACTIVATED
)

if exist "%VSINSTALLDIR%\VC\Auxiliary\Build\vcvarsall.bat" (
  set "EXIT_STATUS=0"
) else (
  set "EXIT_STATUS=1"
)
if "!EXIT_STATUS!"=="0" (
  echo %INFO% MSBuild: VSINSTALLDIR points to "%VSINSTALLDIR%".
  echo:
  echo %OKOK% MSBuild: MS Build Tools activation succeeded.
) else (
  echo %ERROR% MSBuild: MS Build Tools activation failed.
  echo %ERROR% MSBuild: Used script "%_VCVARS:all.bat=64.bat%".
)

:MSBUILD_ACTIVATED

set  "INFO="
set  "OKOK="
set  "WARN="
set "ERROR="
set "_VCVARS="

exit /b %EXIT_STATUS%


:: ============================================================================ COLOR_SCHEME BEGIN
:: ============================================================================
:COLOR_SCHEME
:: ---------------------------------------------------------------------
:: Color Scheme (with NOCOLOR fallback)
:: ---------------------------------------------------------------------

if defined NOCOLOR (
  set  "INFO= [INFO]  "
  set  "OKOK= [-OK-]  "
  set  "WARN= [WARN]  "
  set "ERROR= [ERROR] "
) else (
  set  "INFO=[100;92m [INFO]  [0m"
  set  "OKOK=[103;94m [-OK-]  [0m"
  set  "WARN=[106;35m [WARN]  [0m"
  set "ERROR=[105;34m [ERROR] [0m"
)

exit /b 0
:: ============================================================================ 
:: ============================================================================ COLOR_SCHEME END
```

---
`AIFFCV/pthreads/activate.bat`

```
@echo off

:: =====================================================================
::  Purpose:
::    Configures the MSVC toolchain environment for the PHTREADS-WIN32
::    dependency during a package build (e.g., pip install).
::
::    Intended to be *CALLED* by a parent script to
::    modify the caller's environment, not executed directly.
::
::  Arguments (Optional):
::    -   :     The default workflow with No arguments is to activate
::              environment only if all files are present. This workflow
::              is relevant for normal use of Python environment after 
::              installation is complete. However, is the binaries are
::              copied to CONDA_PREFIX (/i) and the dev files are not meant
::              to be used after installation is complete, this workflow
::              becomes unnecessary (the only runtime requirements of having
::              the DLL containing directory on the PATH is satisfied by
::              Conda environment activation process.
::    - /f:     Force. Sets the environment variables even if
::              target files (.dll, .lib, .h) are not found.
::              Useful for pre-configuring an environment.
::    - /i:     Install. Copies the library's .dll file(s) from
::              their source location to the Conda environment's
::              '%CONDA_PREFIX%\Library\bin' directory.
::              This supersedes the main environment setup logic.
::              This process is a NOOP, if using a conda package.
::              Note: This step is essential for runtime due to
::                    Python DLL loading implementation logic.
::
::  Preconditions:
::    - The CALLER's environment must have delayed expansion enabled
::      *prior* to calling this script. (This script cannot use 'setlocal'
::      as it would prevent modification of the caller's environment).
::    - CONDA_PREFIX or _CONDA_PREFIX must be set.
::    - NOCOLOR: If set, gracefully falls back to no color.
::
::  Postconditions (on success, without /i):
::    - Updates the CALLER's environment:
::      - set "Path=%_BINPATH%;%Path%"
::      - set "INCLUDE=%_INCPATH%;%INCLUDE%"
::      - set "LIB=%_LIBPATH%;%LIB%"
::      - set "LINK=%_LIBNAME% %LINK%"
:: =====================================================================

:: --- Escape sequence templates for color coded console output ---

call :COLOR_SCHEME

:: --- Settings for a Conda packge ---

set "__CONDA_PREFIX="
if defined CONDA_PREFIX (
  set "__CONDA_PREFIX=%CONDA_PREFIX%"
) else (if defined _CONDA_PREFIX (
  set "__CONDA_PREFIX=%_CONDA_PREFIX%"
))
if not defined __CONDA_PREFIX (
  echo %ERROR% %_LIBRARY%: Failed to determine target location.
  echo %ERROR% %_LIBRARY%: One of CONDA_PREFIX or _CONDA_PREFIX must be defined. Aborting...
  exit /b 1
)

:: --- Settings for a standalone copy ---
:: --------------------------------------
:: Note: If using an independent copy of the library, use this code instead.
set "PTH_PREFIX=%~dp0"
if "%PTH_PREFIX:~-1%/"=="\/" set "PTH_PREFIX=%PTH_PREFIX:~0,-1%"

:: --- CONFIG ---

set "_LIBRARY=PTHREADS"
set "_BINPATH=%PTH_PREFIX%\dll\x64"
set "_BINNAME=pthreadVC2.dll"
set "_INCPATH=%PTH_PREFIX%\include"
set "_INCNAME=pthread.h"
set "_INCEXT="
set "_LIBPATH=%PTH_PREFIX%\lib\x64"
set "_LIBNAME=pthreadVC2.lib"
set "PTH_PREFIX="

:: --- Note: The code below this block is generic and library-independent. ---

set "TOTAL_ERRORS=0"
set "EXIT_STATUS=1"

:: --- Argument Parsing ---

set "_FORCE="
set "_DO_INSTALL="

:PARSE_ARGS

if "%~1"=="" goto :PARSE_ARGS_DONE
if /I "%~1"=="/f" set "_FORCE=1"
if /I "%~1"=="/i" set "_DO_INSTALL=1"
shift
goto :PARSE_ARGS

:PARSE_ARGS_DONE

:: --- Route based on flags ---

if defined _DO_INSTALL goto :INSTALL_ENV

:: -----------------------------------------------------------------------------
:: --- Main workflow executed when no argument or "/f" is provided.
:: -----------------------------------------------------------------------------

echo:
echo ==========================================================================
echo %INFO% Setting up --- %_LIBRARY% ---
echo %INFO%
echo %WARN% CLI: "%~f0" %*
echo ==========================================================================
echo:

echo ==========================================================================
echo %INFO% %_LIBRARY%: PATH

set "EXIT_STATUS=0"
for %%I in (%_BINNAME%) do (
  set "_MOD=%_BINPATH%\%%~I"
  if exist "!_MOD!" (
    echo %INFO% %_LIBRARY%:   Library "!_MOD!" found.
  ) else (
    echo %ERROR% %_LIBRARY%:   Library "!_MOD!" NOT found!
    set /a "EXIT_STATUS+=1"
  )
)  
if defined _FORCE (set "EXIT_STATUS=0")
if %EXIT_STATUS% equ 0 (
  echo %INFO% %_LIBRARY%:   "Path=%_BINPATH%;%%Path%%"
  set "Path=%_BINPATH%;%Path%"
) else (
  echo %ERROR% %_LIBRARY%:   PATH NOT UPDATED
)
set /a "TOTAL_ERRORS+=!EXIT_STATUS!"
set "_MOD="
set "EXIT_STATUS="

echo ==========================================================================
echo %INFO% %_LIBRARY%: INCLUDE

set "EXIT_STATUS=0"
for %%I in (%_INCNAME%) do (
  set "_MOD=%_INCPATH%%_INCEXT%\%%~I"
  if exist "!_MOD!" (
    echo %INFO% %_LIBRARY%:   Include "!_MOD!" found.
  ) else (
    echo %ERROR% %_LIBRARY%:   Include "!_MOD!" NOT found!
    set /a "EXIT_STATUS+=1"
  )
)  
if defined _FORCE (set "EXIT_STATUS=0")
if %EXIT_STATUS% equ 0 (
  echo %INFO% %_LIBRARY%:   "INCLUDE=%_INCPATH%;%%INCLUDE%%"
  set "INCLUDE=%_INCPATH%;%INCLUDE%"
) else (
  echo %ERROR% %_LIBRARY%:   INCLUDE NOT UPDATED
)
set /a "TOTAL_ERRORS+=!EXIT_STATUS!"
set "_MOD="
set "EXIT_STATUS="


echo ==========================================================================
echo %INFO% %_LIBRARY%: LIB

set "EXIT_STATUS=0"
for %%I in (%_LIBNAME%) do (
  set "_MOD=%_LIBPATH%\%%~I"
  if exist "!_MOD!" (
    echo %INFO% %_LIBRARY%:   Lib "!_MOD!" found.
  ) else (
    echo %ERROR% %_LIBRARY%:   Lib "!_MOD!" NOT found!
    set /a "EXIT_STATUS+=1"
  )
)  
if defined _FORCE (set "EXIT_STATUS=0")
if %EXIT_STATUS% equ 0 (
  echo %INFO% %_LIBRARY%:   "LIB=%_LIBPATH%;%%LIB%%"
  echo %INFO% %_LIBRARY%:   "LINK=%_LIBNAME% %%LINK%%"
  set "LIB=%_LIBPATH%;%LIB%"
  set "LINK=%_LIBNAME% %LINK%"
) else (
  echo %ERROR% %_LIBRARY%:   LINK NOT UPDATED
)
set /a "TOTAL_ERRORS+=!EXIT_STATUS!"
set "_MOD="
set "EXIT_STATUS="

set "FINAL_EXIT_CODE=%TOTAL_ERRORS%"
goto :CLEANUP
:: ============================================================================
:: ============================================================================
:: ============================================================================


:: ============================================================================ INSTALL_ENV BEGIN
:: ============================================================================
:INSTALL_ENV
:: -----------------------------------------------------------------------------
:: --- Alternative workflow executed when "/i" is provided.
:: -----------------------------------------------------------------------------

echo:
echo %INFO% %_LIBRARY%: SOURCE:      "%_BINPATH%"
echo %INFO% %_LIBRARY%: DESTINATION: "%CONDA_PREFIX%\Library\bin"
echo %INFO% %_LIBRARY%: DLLs:        "%_BINNAME%"
echo:

:: --- Must run from an activated Conda environment. ---

if not defined CONDA_PREFIX (
  echo %ERROR% %_LIBRARY%: Run installation command from an activated Conda environment. Aborting...
  set "FINAL_EXIT_CODE=1"
  goto :CLEANUP
)

:: --- Check if already within the CONDA_PREFIX. ---

if "%_BINPATH%"=="%CONDA_PREFIX%\Library\bin" (
  echo %INFO% %_LIBRARY%: _BINPATH - "%_BINPATH%" is within CONDA_PREFIX - "%CONDA_PREFIX%". Skipping...
  set "FINAL_EXIT_CODE=0"
  goto :CLEANUP
)

:: --- Check if CONDA_PREFIX has conflicting DLLs. ---

set "EXIT_STATUS=0"
for %%I in (%_BINNAME%) do (
  if exist "%CONDA_PREFIX%\Library\bin\%%~I" (
    echo %ERROR% %_LIBRARY%: A conflicting name "%%~I" is present in CONDA_PREFIX.
    set "EXIT_STATUS=1"
  )
  if not exist "%_BINPATH%\%%~I" (
    echo %ERROR% %_LIBRARY%: Source not found: "%_BINPATH%\%%~I".
    set "EXIT_STATUS=1"
  )
)
if not "%EXIT_STATUS%"=="0" (
  echo %ERROR% %_LIBRARY%: Pre-flight checks failed. Aborting...
  set "FINAL_EXIT_CODE=%EXIT_STATUS%"
  goto :CLEANUP
)

:: --- Copy DLLs to CONDA_PREFIX. ---

echo %INFO% %_LIBRARY%: Copying files to "%CONDA_PREFIX%\Library\bin"
set "EXIT_STATUS=0"
for %%I in (%_BINNAME%) do (
  copy /Y "%_BINPATH%\%%~I" "%CONDA_PREFIX%\Library\bin\%%~I" > nul
  if not "!ERRORLEVEL!"=="0" (
    echo %ERROR% %_LIBRARY%: Failed to copy "%_BINPATH%\%%~I" to "%CONDA_PREFIX%\Library\bin\%%~I".
    set "EXIT_STATUS=1"
  ) else (
    echo %INFO% %_LIBRARY%: Copied "%_BINPATH%\%%~I" to "%CONDA_PREFIX%\Library\bin\%%~I".
  )
)
if "%EXIT_STATUS%"=="0" (
  echo %OKOK% %_LIBRARY%: Copy complete.
) else (
  echo %ERROR% %_LIBRARY%: Failed to copy libraries above.
)
set "FINAL_EXIT_CODE=%EXIT_STATUS%"
goto :CLEANUP
:: ============================================================================ 
:: ============================================================================ INSTALL_ENV END


:: ============================================================================ COLOR_SCHEME BEGIN
:: ============================================================================
:COLOR_SCHEME
:: ---------------------------------------------------------------------
:: Color Scheme (with NOCOLOR fallback)
:: ---------------------------------------------------------------------

if defined NOCOLOR (
  set  "INFO= [INFO]  "
  set  "OKOK= [-OK-]  "
  set  "WARN= [WARN]  "
  set "ERROR= [ERROR] "
) else (
  set  "INFO=[100;92m [INFO]  [0m"
  set  "OKOK=[103;94m [-OK-]  [0m"
  set  "WARN=[106;35m [WARN]  [0m"
  set "ERROR=[105;34m [ERROR] [0m"
)

exit /b 0
:: ============================================================================ 
:: ============================================================================ COLOR_SCHEME END


:: ============================================================================ CLEANUP BEGIN
:: ============================================================================
:: --- Clean up; prefer as the primary script exit point ---
:: To exit script, set FINAL_EXIT_CODE and goto CLEANUP

:CLEANUP

set "_LIBRARY="
set "_BINPATH="
set "_BINNAME="
set "_INCPATH="
set "_INCNAME="
set "_LIBPATH="
set "_LIBNAME="

set  "INFO="
set  "OKOK="
set  "WARN="
set "ERROR="
set "_FORCE="
set "_DO_INSTALL="
set "EXIT_STATUS="
set "TOTAL_ERRORS="

:: --- Ensure a valid exit code is always returned ---

if not defined FINAL_EXIT_CODE set "FINAL_EXIT_CODE=1"
exit /b %FINAL_EXIT_CODE%
:: ============================================================================ 
:: ============================================================================ CLEANUP END
```