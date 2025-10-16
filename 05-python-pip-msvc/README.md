<!--
https://chatgpt.com/c/68ed5ca2-ee7c-8330-a5d1-0d4b81ee3aa0
-->
![](./vis1.jpg)

# **Python pip Fails to Detect MS Build Tools on Windows**

## **Summary**

| Aspect       | Description                                                                        |
| ------------ | ---------------------------------------------------------------------------------- |
| **Symptom**  | pip cannot detect MSVC Build Tools, even though they are installed and functional. |
| **Cause**    | `setuptools._distutils` fails to check environment variables or PATH entries.      |
| **Fix**      | Use `DISTUTILS_USE_SDK=1` or patch _find_vcvarsall() to fall back on PATH lookup   |
| **Verified** | Works with MSVC 19.44.35217 and Python 3.13.8 on Windows 10.                       |

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

In other words:

> The detection logic is defective - it looks in registry keys and default paths but never verifies whether the compiler is already usable.

This deficiency makes detection process incompatible with portable, script-driven, or Conda-based setups.

Other test packages such as `psutil` produced less informative traces, offering no clue to the actual source of failure, yet they are affected by the same flaw.

### **Build Isolation Caveat**

Modern versions of pip may build packages inside an **isolated environment** by default. Because the faulty detection logic resides in `setuptools`, patching it (see Option 2 below) only affects the installed copy of that module. During isolated builds, pip instead uses a temporary copy, making the patch ineffective.

To ensure the fix applies, builds must be run with isolation disabled:

```
pip install --no-binary :all: --no-build-isolation --no-cache-dir pycryptodome
```

- `--no-build-isolation` ensures pip uses the local (patched) `setuptools`.
- `--no-cache-dir` prevents reuse of cached wheels or build artifacts.
- `--no-binary :all:` prevents installation of prebuild binaries, even if available, forcing local compilation.

When testing the patch, omitting either flag can lead to false positives (e.g., pip using cached binaries instead of recompiling) or false negatives.

## **Workaround / Temporary Fix**

There are two ways to address the issue, depending on your environment setup.

### **Option 1 - Environment Variable Flag (Recommended)**

In your shell activation script, add (the first line should be adjusted appropriately):

```batch
call "<Path_To_Build_Tools>\Microsoft Visual Studio\<YEAR>\BuildTools\VC\Auxiliary\Build\vcvars64.bat"
set "DISTUTILS_USE_SDK=1"
```

Then run your installation command, e.g.:

```bash
pip install --no-binary :all: --no-cache-dir pycryptodome
```

The set `DISTUTILS_USE_SDK` variable tells the Python build system to skip compiler auto-detection and use the existing toolchain defined in the current environment. It effectively bypasses the defective `_find_vcvarsall()` logic without any code modifications and effective in both isolated and non-isolated building modes.

While not prominently documented, this behavior is implemented within the same `msvc.py` module and supported by `setuptools._distutils`, providing a clean, non-invasive solution.

### **Option 2 - Manual Patch (Fallback)**

An alternative approach, mostly of educational value, rather than practical, patching setuptools directly.

1. Add the directory containing `vcvarsall.bat` to your session or system `PATH`.
2. Edit the file:

```
Lib\site-packages\setuptools\_distutils\compilers\C\msvc.py
```

Locate the `_find_vcvarsall()` function and insert the following lines immediately after the `_find_vc2015()` call:

```python
if not best_dir:
    import shutil
    best_dir = os.path.dirname(shutil.which("vcvarsall.bat"))
```

This modification lets setuptools detect the compiler dynamically whenever the `vcvarsall.bat` directory is visible on `PATH`.

After applying the patch:
- `pip install --no-build-isolation` succeeds normally.
- The same command **without** the flag still fails, as isolated builds use a temporary `setuptools` copy.

Interestingly, even though some packages (like `psutil`) produce no trace referencing `msvc.py`, this same patch still resolves their build failures—indicating that the same internal detection bug is responsible.

