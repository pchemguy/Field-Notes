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

Focusing specifically on searching for the required modules, there are three major error groups:
**1.** compiler
   When required `*.h` header files (that is called in `#include` statements) are not found in directories indicated in the compiler's command line or via the `INCLUDE` environment variable, compiler should generally emit a related error, indicating unresolved identifiers and, thus, pointing to the source of error (at least roughly).
**2.** linker
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

**3.** package loading process (run-time, OS/Python)
   The primary error message emitted by this process states that a ==certain library file cannot be found==. This is, perhaps, one of the most problematic errors to troubleshoot, as this error may occur, because the specified module
   - is in fact not found.
   - is incompatible (mismatched version/variant or name clashing).
   - one of its dependencies are missing or incompatible.
   Without additional details/clues, resolving such an issue may prove not practically feasible.
