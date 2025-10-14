<!--
https://chatgpt.com/c/68ed5ca2-ee7c-8330-a5d1-0d4b81ee3aa0
-->
![](./vis1.jpg)

# **Python pip Fails to Detect MSVC Build Tools on Windows**

## **Summary**

| Aspect       | Description                                                                        |
| ------------ | ---------------------------------------------------------------------------------- |
| **Symptom**  | pip cannot detect MSVC Build Tools, even though they are installed and functional. |
| **Cause**    | `setuptools._distutils` fails to check environment variables or PATH entries.      |
| **Fix**      | Patch `_find_vcvarsall()` to fall back to PATH lookup for `vcvarsall.bat`.         |
| **Verified** | Works with MSVC 19.44.35217 and Python 3.11.13 on Windows 10.                      |

## **Problem**

When installing certain Python packages from source on Windows, pip may fail to detect the Microsoft Visual C++ Build Tools - even when they are correctly installed and working.

Example (Windows 10, Python 3.11.13, pip 25.2, setuptools 80.9.0):

```bash
pip install --no-binary :all: pycryptodome
```

This command results in the familiar but misleading error:

```
  distutils.errors.DistutilsPlatformError: Microsoft Visual C++ 14.0 or greater is required.
  Get it with "Microsoft C++ Build Tools":
  https://visualstudio.microsoft.com/visual-cpp-build-tools/
```

Despite this, the compiler works perfectly from the same shell:

```bash
G:\dev\AIPY\Anaconda>cl
Microsoft (R) C/C++ Optimizing Compiler Version 19.44.35217 for x64
Copyright (C) Microsoft Corporation.
```

Most online sources (including Stack Overflow threads and LLM suggestions) simply advise reinstalling MS Build Tools and do not address the underlying detection issue.

## **Investigation**

Tracing the problem is not straightforward. While we only care about the compiler detection logic, even that process varies significantly.  To isolate it, I tested several packages requiring native C module compilation using:

```bash
pip install --no-binary :all: --no-cache-dir
```

The first candidate, `pycryptodome`, luckily yielded a useful trace that pointed directly to the failing routine `_get_vc_env()` inside:

```
Lib\site-packages\setuptools\_distutils\compilers\C\msvc.py
```

This function is responsible for locating MSVC toolchains. Its call chain is:

- `_get_vc_env()` → `_find_vcvarsall()`
- `_find_vcvarsall()` → `_find_vc2015()` / `_find_vc2017()`

These functions attempt to discover MSVC installations through registry keys (`SxS\VC7`) and vswhere.exe lookups. This approach works for full Visual Studio installations but fails for standalone MS Build Tools setups.

Users of the standalone MS Build Tools typically initialize the compiler environment manually using `vcvarsall.bat` or its variants. However, the current `distutils` logic never checks for:

- `vcvarsall.bat` already being accessible on `PATH`,
- common environment variables set by `vcvarsall.bat`, or
- existing compiler executables such as `cl.exe` and `link.exe`.

As a result, pip fails to locate MSVC even when the environment is already properly configured.

In short:

> The detection logic assumes a full Visual Studio installation and ignores compiler environments initialized via shell scripts.

This deficiency makes detection process incompatible with portable, script-driven, or Conda-based setups.

Other test packages such as `psutil` produced less informative traces, offering no clue to the actual source of failure, yet they are affected by the same flaw.

### **Build Isolation Considerations**

Modern versions of pip may build packages inside an **isolated environment** by default. Because the faulty detection logic resides in `setuptools`, patching it only affects the installed copy of that module. During isolated builds, pip instead uses a temporary copy, making the patch ineffective.

To ensure the fix applies, builds must be run with isolation disabled:

```
pip install --no-binary :all: --no-build-isolation --no-cache-dir pycryptodome
```

- `--no-build-isolation` ensures pip uses the local (patched) `setuptools`.
- `--no-cache-dir` prevents reuse of cached wheels or build artifacts.
- `--no-binary :all:` prevents installation of prebuild binaries, even if available, forcing local compilation.

When testing the patch, omitting either flag can lead to false positives (e.g., pip using cached binaries instead of recompiling) or false negatives.

## **Workaround / Temporary Fix**

1. Add the directory containing `vcvarsall.bat` to your session or system `PATH`.    
2. Patch the _distutils_ helper to dynamically check for `vcvarsall.bat`.

In:

```
Lib\site-packages\setuptools\_distutils\compilers\C\msvc.py
```

Locate the `_find_vcvarsall()` function and insert the following lines immediately after the `_find_vc2015()` call:

```python
if not best_dir:
    import shutil
    best_dir = os.path.dirname(shutil.which("vcvarsall.bat"))
```

This change lets setuptools detect the compiler whenever the `vcvarsall.bat` directory is visible via `PATH`.

After applying the patch:
- `pip install --no-build-isolation` succeeds without errors.
- The same command **without** that flag still fails (as expected), since isolated builds use a separate `setuptools` instance.

Interestingly, although `psutil`’s trace shows no reference to `msvc.py`, this same patch enables its compilation as well - confirming that the issue lies in the same faulty detection logic.

## **Notes**

- The root cause is the outdated compiler discovery mechanism inherited from legacy `distutils`.    
- A proper upstream fix should:
    - Check for existing compiler-related environment variables.
    - Detect the presence of `cl.exe` or `vcvarsall.bat` on PATH.
- This workaround is non-invasive and works seamlessly with virtual or Conda environments.
