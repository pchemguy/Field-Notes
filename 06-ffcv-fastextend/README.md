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