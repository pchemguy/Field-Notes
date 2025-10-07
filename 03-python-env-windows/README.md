# Bootstrapping Python Environments on Windows with Micromamba

## TL;DR

This guide presents a safe and robust workflow for bootstrapping Conda-based Python environments on Windows using the standalone executable **`micromamba.exe`**. It specifically avoids using the standard `micromamba shell init` command, which dangerously modifies the Windows Registry (`AutoRun`). Instead, it details a manual, script-based approach that ensures clean, isolated, and portable environments by correctly setting environment variables and calling the `micromamba.bat` wrapper for activation.

---

## 1. The Philosophy: Isolated Python Environments

On Windows, which lacks a system-level Python installation, a common approach is to install a global Python and create virtual environments from it. However, this approach can be fragile, as a broken or deficient activation script might cause an application to silently fall back to the system Python, leading to subtle errors.

A more robust approach is to have **no system-level Python**. Instead, each Python environment is a standalone, isolated directory. A shell session is either "clean" (with no Python in its `PATH`) or has a single environment explicitly activated. This design ensures that if activation fails, the application fails loudly rather than using the wrong interpreter.

---

## 2. The Tool: Micromamba for Bootstrapping

**Micromamba** is a good tool for this philosophy. It is a single, standalone executable with no Python dependency, making it perfect for scripting the creation of a minimal Conda environment from a clean slate.

---

## 3. The Problem: Micromamba's Quirks on Windows

While powerful, using Micromamba on Windows requires navigating several issues with its official documentation and scripts:
- **Broken Install Scripts:** The provided `install.bat` script for "cmd.exe" shell is syntactically incorrect and unusable.
- **Misleading `activate` Command:** Running `micromamba.exe activate` directly fails with a "Shell not initialized" error, and its help text is confusing.
- **Dangerous `shell init` Command:** The `micromamba shell init` command is the documented way to "initialize" the shell, but it creates an `AutoRun` entry in the Windows Registry. This forces a script to run with every new `cmd.exe` instance—a practice that is invasive and can lead to system-wide issues.
- **`.exe` vs. `.bat` Confusion:** The initialization process creates a `micromamba.bat` wrapper. Critical operations fail when calling `micromamba.exe` directly but succeed when using `micromamba.bat` because the wrapper sets essential environment variables (`MAMBA_ROOT_PREFIX`) that the executable expects.

---

## 4. The Solution: A Safe and Repeatable Workflow

This workflow avoids the pitfalls above by using a manual, script-based approach.

### Step 1: Manual Installation of Micromamba

Instead of using the broken install scripts, download the `micromamba.exe` binary directly from the [official releases repo](https://github.com/mamba-org/micromamba-releases). Create your target environment directory (e.g., `C:\my-env`) and place the executable inside a `Scripts` subdirectory: `C:\my-env\Scripts\micromamba.exe`.

### Step 2: Bootstrap the Base Environment

From a clean `cmd.exe` shell, run the `create` command. This will download and install Python, Conda, and Mamba into your environment.

Code snippet

```
C:\my-env\Scripts\micromamba.exe create -p C:\my-env -c conda-forge python=3.11 conda mamba --yes
```

- `-p C:\my-env`: Specifies the target environment directory (prefix).
    
- `-c conda-forge`: Specifies the channel to download packages from.
    

### Step 3: Create a Safe Activation Script

Instead of using `shell init`, create your own `activate.bat` script inside your environment directory (`C:\my-env\activate.bat`). This script will correctly set the required environment variables and modify the `PATH`.

**Example `C:\my-env\activate.bat`:**

Code snippet

```
@echo off
:: Set the root prefix, which is essential for micromamba.bat
set "MAMBA_ROOT_PREFIX=%~dp0"

:: Prepend the necessary directories to the PATH
:: This order ensures `micromamba.bat` is found before `micromamba.exe`
set "PATH=%MAMBA_ROOT_PREFIX%condabin;%MAMBA_ROOT_PREFIX%Scripts;%MAMBA_ROOT_PREFIX%Library\bin;%PATH%"

:: Set the environment prompt indicator
set "PROMPT=($env:CONDA_DEFAULT_ENV) $P$G"

echo Environment activated. Use 'conda' or 'mamba' to manage packages.
```

Now, you can run `C:\my-env\activate.bat` to safely activate your environment in any shell.

---

## 5. Deeper Dive: Understanding the Mechanics

### Why `micromamba shell init` is Dangerous

The `init` command creates the following registry key:

Code snippet

```
[HKEY_CURRENT_USER\SOFTWARE\Microsoft\Command Processor]
"AutoRun"="C:\path\to\your\env\condabin\mamba_hook.bat"
```

The `AutoRun` key forces `cmd.exe` to execute the specified script upon every launch, modifying the shell environment globally. This is a brittle and non-portable approach that should be avoided.

### The `micromamba.exe` vs. `.bat` Mystery

When `micromamba.exe` complains about an uninitialized shell, it's often because the `MAMBA_ROOT_PREFIX` environment variable is not set. The `mamba_hook.bat` and `micromamba.bat` scripts (created by `init` or `hook` commands) handle setting this variable. By calling `micromamba.bat` directly (which our custom activation script ensures by setting the `PATH` order), we provide the necessary context for the executable to function correctly.

### Enabling Long File Paths

Conda environments can have deeply nested paths. It's highly recommended to enable long path support on Windows.

Code snippet

```
reg add HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\FileSystem /v LongPathsEnabled /t REG_DWORD /d 1 /f
```