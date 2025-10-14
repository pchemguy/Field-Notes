<!--
https://chatgpt.com/c/68ed5ca2-ee7c-8330-a5d1-0d4b81ee3aa0
-->
![](./vis1.jpg)
# **Python pip Fails to Detect MSVC Build Tools on Windows**

## **Summary**

| Aspect       | Description                                                                        |
| ------------ | ---------------------------------------------------------------------------------- |
| **Symptom**  | Pip cannot find MSVC Build Tools despite them being installed and functional       |
| **Cause**    | `setuptools._distutils` fails to check environment variables or PATH               |
| **Fix**      | Manually patch `_find_vcvarsall()` to fall back on PATH lookup for `vcvarsall.bat` |
| **Verified** | Works with MSVC 19.44.35217 and Python 3.11.13 on Windows 10                       |

## **Problem**

When attempting to install certain Python packages from source on Windows, pip may fail to detect the Microsoft Visual C++ Build Tools - even when they are properly installed and working.

Example (Windows 10, Python 3.11.13, pip 25.2, setuptools 80.9.0):

```bash
pip install --no-binary :all: --no-cache-dir pycryptodome
```

Results in the familiar but unhelpful error:

```
  distutils.errors.DistutilsPlatformError: Microsoft Visual C++ 14.0 or greater is required.
  Get it with "Microsoft C++ Build Tools":
  https://visualstudio.microsoft.com/visual-cpp-build-tools/
```

Despite the fact that the compiler works perfectly from the same shell:

```bash
G:\dev\AIPY\Anaconda>cl
Microsoft (R) C/C++ Optimizing Compiler Version 19.44.35217 for x64
Copyright (C) Microsoft Corporation.
```

Online results (including Stack Overflow and Gemini bot) are superficial (e.g., suggesting installing MS Build Tools) and do not provide any working solution for this case.

## **Investigation**

Tracking the actual cause of the problem might be a tricky process. While we are solely interested in the part involving detection of the build toolchain, even this process has substantial variations. I have attempted to run `pip install --no-binary :all: --no-cache-dir` on several packages suggested by Gemini as test cases for the installation process that requires compilation of `C` modules. Accidentally, the first suggestion, `pycryptodome`, produced an error trace that not only included the complaint about missing MSVC, but also pointing to the actual culprit, the routine `_get_vc_env()` in

```
setuptools\_distutils\compilers\C\msvc.py
```

Specifically, the `_get_vc_env()` routine, which is responsible for locating MSVC toolchains. Tracing the function chain:

- `_get_vc_env()` → `_find_vcvarsall()`
- `_find_vcvarsall()` → `_find_vc2015()` and `_find_vc2017()`

These routines attempt to discover MSVC installations via **registry keys** (`SxS\VC7`) and **vswhere.exe** lookups. The logic is sound for full Visual Studio installs, but **incomplete** for standalone _Build Tools_ setups.

Build Tools users typically initialize the compiler environment manually via the provided `vcvarsall.bat` (or a variant thereof). However, the *distutils* logic never checks for:

- `vcvarsall.bat` being already available on `PATH`
- characteristic environment variables, set commonly after  a `vcvarsall.bat` call
- existing compiler environment (`cl.exe`, `link.exe`, etc.)

As a result, pip fails to find MSVC even when it is available and configured for the current session.

 Evidently, `setuptools._distutils` assumes a traditional Visual Studio installation and ignores any compiler environment configured via shell scripts.  
This behavior is not compatible with portable or script-initialized MSVC Build Tools setups - a common pattern for automated or Conda environments.

In short:

> The detection logic is defective - it checks registry keys and default paths, but never verifies whether the compiler is already available.

Attempts to install other suggested "test" packages, such as `psutil`, produced completely useless traces only containing the complaint about missing MSVC and no references to error source location.

Another potential problem is associated with the modern building process involving an isolated environment.  Depending on Python version this isolated mode may or may not be enabled by default. The reason this isolated process is problematic in present context is because the defective MSVC detection logic is in a `setuptools` module. As discussed bellow, the copy of this module installed on the Python environment being used can be patched as a workaround. However, while in the non-isolated building mode such a patch fixes this particular problem, in the isolation mode `pip` does not use the  installed copy of `setuptools`. For this reason, this workaround will only work in the non-isolated module, necessitating and additional flag `--no-build-isolation` to `pip install`:

```
pip install --no-binary :all: --no-build-isolation --no-cache-dir pycryptodome
```

This flag has limited official [documentation](https://pip.pypa.io/en/stable/cli/pip_install/#cmdoption-no-build-isolation) and certain limitations.

Another important flag necessary for the testing purposes is `--no-cache-dir`. When verifying efficacy and necessity of the patch, it is essential that pip does not used a cached copy built with the fix discussed below enabled. Otherwise, after disabling the fix and uninstalling the test package, subsequent attempt to reinstall it, which should fail again due to disabled fix, will not actually fail, because `pip` will use a cached compiled copy instead of attempting to recompile it.


## **Workaround / Temporary Fix**

1. Add the containing directory of `vcvarsall.bat` to the system or session `PATH`.
2. Patch the *distutils* helper manually to make it check for `vcvarsall.bat` dynamically.

Inside:

```
Lib\site-packages\setuptools\_distutils\compilers\C\msvc.py
```

Locate the `_find_vcvarsall()` function and insert the following lines after the `_find_vc2015()` call:

```python
if not best_dir:
    import shutil
    best_dir = os.path.dirname(shutil.which("vcvarsall.bat"))
```

This addition allows setuptools to pick up the compiler when the `vcvarsall.bat` directory is already accessible via `PATH`. After this modification, the same pip install command succeeds without errors.

## **Notes**

- The core issue lies in outdated compiler discovery logic inherited from the legacy `distutils` module.
- The upstream fix should ideally include:
    - Environment variable checks
    - Detection of `cl.exe` or `vcvarsall.bat` presence
- This workaround is non-invasive and compatible with virtual environments or Conda shells.

