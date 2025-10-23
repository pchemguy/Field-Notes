FFCV package has three native library dependencies required for building the package:
- OpenCV
- LibJPEG-Turbo
- pthreads-win32

LibJPEG-Turbo and pthreads-win32 are C/C++ dependencies, whereas OpenCV is called from both C++ (native dependency) and Python (Python package dependency) modules. In turn, there are three major distinct sources of dependencies:
- official releases (typically available from GitHub or project sites, such as [opencv.org](https://opencv.org))
- PyPI Python packages (such, as [opencv-python](https://pypi.org/project/opencv-python))
- Conda Python packages (such as, [opencv](https://anaconda.org/conda-forge/opencv))

Because binaries 


## MSVC Building Considerations - ABI Compatibility

To build and run a package with native dependencies successfully on Windows, it essential that
- MSVC compiler is told
    - Where to search for necessary `*.h` header files (e.g., via the `INCLUDE` environment variable).
- Linker is told
    - Where to search for necessary `*.lib` import library files (e.g., via the `LIB` environment variable).
    - Which specific `*.lib` import library file names to use
- The OS is told
    - Where to search for associated `*.dll` library files.

Potential issues
- Name clashing
      When Compiler/Linker/OS search for required `*.h`/`*.lib`/`*.dll` files, they will attempt to use the first file with matching name found and will fail, if the found file is not "compatible". While name clashing might arise between the required dependencies, a more likely cause is between multiple different versions/variants of the same dependency exposed to the build toolchain or the OS:
        - OS integrates and provides an older version of dependency system-wise (this is primarily run-time `*.dll` concern, as developer `*.h`/`*.lib` files are not generally included in stock Windows and are provided as part of a separate Win SDK installation),
        - OS does not integrate such a dependency out-of-the-box, but the user installed such a dependency system-wise previously (instead of including it as part of an isolated environment); some of the third-party applications may also perform such installation (also most likely may affect `*.dll`, rather than `*.h`/`*.lib`).
        - a managed isolated environment ecosystem may need to include a particular dependency in user-configured environment.
        - a non-managed copy of the dependency acquired by the user.
- Feature or ABI incompatibility due to mismatched dependency version or the toolset used to build a binary dependency (may happen due to incorrectly selected version/variant OR due to name clashing).
- Missing paths

For example, `pthreads-win32` library is available on Windows 10 as a system-level component (system-level variants of third-party libraries often use a particular naming convention to reduce the risk of name clashing with user provided non-system variants of the same library).  The same library may be included as a managed component of an isolated Conda environment (depending on environment specification). Finally, a PyPI package may also have `pthreads-win32` dependency, but, because pip-managed PyPI ecosystem is distinct from the Conda ecosystem, `pip` may install a separate copy of `pthreads-win32` or it might be necessary to provide a separate copy of the library manually.

- Feature compatibility
      The author of the package needs to specify compatible version of dependencies that provide expected functionality needed by the package.
- ABI stability
      While the C ABI (`extern C` calls) are quite stable, especially when compiled using the native MSVC toolchain, the C++ ABI has been relatively "volatile" on Windows until MSVS 2015. Starting from MSVS 2015, all versions with the same major number (`14.*`) have [generally compatible the C++ ABI](https://learn.microsoft.com/en-us/cpp/porting/binary-compat-2015-2017) (unless dependency is built with `/GL`, [whole program optimization](https://learn.microsoft.com/en-us/cpp/build/reference/gl-whole-program-optimization), or `/LTCG`, [link-time code generation](https://learn.microsoft.com/en-us/cpp/build/reference/ltcg-link-time-code-generation), switches), that is dependencies built by different MSVC versions with the same major number can be mixed. Import libraries, however, are generally not backward compatible, meaning the particular MSVS version must be as new as the newest MSVC version used for building all import libraries used.

Focusing specifically on searching for the required modules, there are four major error groups:
**1.** `pip`/`setuptools`/`setup.py`
   When required `*.h` header files (that is called in `#include` statements) are not found in directories indicated in the compiler's command line or via the `INCLUDE` environment variable, compiler should generally emit a related error, indicating unresolved identifiers and, thus, pointing to the source of error (at least roughly).

```
G:\dev\Anaconda\FFCVTest3\Anaconda>pip install ffcv

Collecting ffcv
  Using cached ffcv-1.0.2.tar.gz (2.6 MB)
  Preparing metadata (setup.py) ... error
  error: subprocess-exited-with-error

  × python setup.py egg_info did not run successfully.
  │ exit code: 1
  ╰─> [8 lines of output]
      Traceback (most recent call last):
        File "<string>", line 2, in <module>
        File "<pip-setuptools-caller>", line 35, in <module>
        File "C:\Users\pcuser\AppData\Local\Temp\pip-install-0kju4u76\ffcv_8ca97d5276f84a38ae7cd4a4d58e5d54\setup.py", line 87, in <module>
          extension_kwargs = pkgconfig_windows('opencv4', extension_kwargs)
        File "C:\Users\pcuser\AppData\Local\Temp\pip-install-0kju4u76\ffcv_8ca97d5276f84a38ae7cd4a4d58e5d54\setup.py", line 62, in pkgconfig_windows
          raise Exception(f"Could not find required package: {package}.")
      Exception: Could not find required package: opencv4.
      [end of output]
```

Note, example above shows complex paths due to default `isolated environment` mode installation. However, `setup.py` of `ffcv` is still clearly identified.

**2.** compiler
   When required `*.h` header files (that is called in `#include` statements) are not found in directories indicated in the compiler's command line or via the `INCLUDE` environment variable, compiler should generally emit a related error, indicating unresolved identifiers and, thus, pointing to the source of error (at least roughly).
**3.** linker
   When correct search paths and file names for the required `*.lib` import library files are specified in the linker's command line or via the `LIB` (for paths) and `LINK` (for space separated list of file names) environment variables, linker should generally emit a related error about a missing dependency. A likely indistinguishable  error message will likely be emitted if incompatible `*.lib` files are provided or if an accidental name clashing occur and the linker finds a wrong module first. Importantly, the error message should include a list of unresolved identifiers that hints at which dependencies caused the error.

```
libffcv.obj : error LNK2001: unresolved external symbol tjTransform
libffcv.obj : error LNK2001: unresolved external symbol tjInitDecompress
libffcv.obj : error LNK2001: unresolved external symbol tjDecompress2
libffcv.obj : error LNK2001: unresolved external symbol tjFree
libffcv.obj : error LNK2001: unresolved external symbol tjInitTransform
build\lib.win-amd64-cpython-311\ffcv\_libffcv.cp311-win_amd64.pyd : fatal error LNK1120: 5 unresolved externals
error: command 'G:\\dev\\MSBuildTools\\VC\\Tools\\MSVC\\14.44.35207\\bin\\HostX64\\x64\\link.exe' failed with exit code 1120
```

**4.** package loading process (run-time, OS/Python)
   The primary error message emitted by this process states that a ==certain library file cannot be found==. This is, perhaps, one of the most problematic errors to troubleshoot, as this error may occur, because the specified module
   - is in fact not found.
   - is incompatible (mismatched version/variant or name clashing).
   - one of its dependencies are missing or incompatible.
   Without additional details/clues, resolving such an issue may prove not practically feasible.

```
Traceback (most recent call last):
  File "<string>", line 1, in <module>
  File "G:\dev\Anaconda\FFCVTest3\Anaconda\lib\site-packages\ffcv\__init__.py", line 1, in <module>
    from .loader import Loader
  <INTERMEDIATE TRACE DETAILS>
  File "G:\dev\Anaconda\FFCVTest3\Anaconda\lib\site-packages\ffcv\libffcv.py", line 6, in <module>
    import ffcv._libffcv
ImportError: DLL load failed while importing _libffcv: The specified module could not be found.
```
   
The section on DLL loading troubleshooting should be extended.
Two essential tools to again insights into what is going are [Dependencies](https://github.com/lucasg/Dependencies) and [Sysinternals Process Monitor](https://learn.microsoft.com/en-us/sysinternals/downloads/procmon). The last installation step of the provided scripts is copying DLLs of external dependencies, `OpenCV` and `pthreads-win32` are used as such external dependencies, while the Conda package for LibJPEG-Turbo is used in present setup to fulfill the third dependency. Early iterations of the presented scripts did not involve copying the required `OpenCV` and `pthreads-win32` DLLs into Python environments, but instead the scripts added external location to the `Path`. In theory this configuration should provide the OS the necessary information to find all dependencies. However, attempted test command `python -c "import ffcv"` resulted in error shown in this screenshot:

{}

Since the module in question, `_libffcv.cp310-win_amd64.pyd` was in the root of the `ffcv` package being imported, I opened it in Dependencies. The screenshot below shows that Python DLL and the three library dependencies are missing. Ok, so while Dependencies is not a console application (though it provides a command-line variant as well), when the process is started, it should inherit parent's environment, including `Path`. If it is started from plain shell or Windows Explorer, the process normally inherits the default system shell. But that is not exactly what the OS should see, when attempting `import ffcv`. In that case, the command was executed from an activated shell, including locations of dependencies. After I started a new copy of `Dependencies` from an activated (via the `conda_far.bat` script) shell, the picture has changed to expected successful resolution of all dependencies, meaning the `Path` should be in fact set correctly.

{}

The next level of insight not provided by Windows would be to sneak pick at the actual dependency loading process. And that is where the Process Monitor shines. Specifically, I wanted to focus on the actual DLL search process, focusing on DLL names shown in the `Dependencies` screenshots. The first step is configuration. Before capturing the events, we want to tell ProcMon to show file events only, and create four  *include* filters,
- Process name is `python.exe`
- Path ends with {DLL_NAME} (one for each dependency)
as shown in the screenshot below

{}

Once filters are all set, activate the capture mode and run `python -c "import ffcv"` from an activated shell, and voila. The result displayed below correspond to the early bootstrapping variant not involving copying the external dependencies into Conda environment. (To see the same output, the DLL would need to be removed from the created Conda environment.)

{}

The only line with result reading "FILE LOCKED..." is for the `turbojpej.dll` which, as ca be seen from the `Path` column is the module sitting in the standard location of the Conda environment. All other lines read "NAME NOT FOUND", which is expected given the indicated locations. It also makes sense that the first places Python checks is the directory containing the `pyd` module (the `ffcv` package top directory with `site-packages`). That location is checked for all three files unsuccessfully, as expected. The critical observation is that the only location checked outside the Conda environment is `%SystemRoot%\System32`. Every other path component outside the Conda environment is ignored. According to Google Gemini (I do not see a solid source right away), "DLL Search Order in Python 3.8+ on Windows: Current Working Directory and PATH: In Python 3.8 and later, the current working directory and directories listed in the system's PATH environment variable are not included in the default DLL search path for dependent DLLs of extension modules. This change was implemented to mitigate DLL hijacking vulnerabilities." So `Path` is no longer a good tool for the task. While there are several approaches to resolve the issue, the least invasive that does not touch FFCV's source code would be to copy DLLs into one of the directories shown as checked in the ProcMon's screenshot. There are two natural places - the `ffcv` package directory, if these libraries are only needed for this package only, or, perhaps the standard location - `Library/bin`, which is what the provided scripts do at the end.
