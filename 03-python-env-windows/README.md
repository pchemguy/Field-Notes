# **Bootstrapping and Managing Python Environments on Windows (via Micromamba)**

## **Executive Summary**

This document describes a simplified and reproducible workflow for initializing Conda-based Python environments on Windows without relying on shell initialization or automatic activation. The approach focuses on transparent environment construction, deterministic behavior, and compatibility with standard Python tools.

The presented method eliminates issues related to Micromamba’s shell hook logic and implicit state persistence, while maintaining a lightweight structure.  
All essential actions - environment creation, configuration, and activation - are handled through explicit commands defined in dedicated batch scripts.

The repository contains:

- Two annotated batch scripts implementing the described workflow
    - `Micromamba_bootstrap.bat`
    - `get_sed.bat`;
- This README, providing background, design notes, and usage documentation;
- Drafts and raw discovery/exploration notes, which include some additional broader or more technical details not presently included in the README.

Together, these materials form a concise reference implementation for controlled Micromamba-based environment bootstrapping on Windows.

---

## **1. Background and Motivation**

Traditional Python environment management assumes a system-level Python installation that serves as the base interpreter for user-created virtual environments.  
While this is common practice, it introduces several fragility points — especially on Windows, where Python is not part of the base system:

- Environment activation relies on environment variable inheritance (`PATH`, `PYTHONPATH`), which can inadvertently reference the wrong interpreter.
    
- Misordered `PATH` entries may cause fallback to system installations rather than failing explicitly.
    
- Shell initialization files or activation hooks may persist undesired configurations across sessions.
    

The workflow described here adopts a more isolated and deterministic approach:

- **No system-wide Python installation** — every environment is self-contained.
    
- **At most one environment per shell** — each shell session is either clean or linked to exactly one environment.
    
- **No persistent shell hooks or autorun modifications.**
    

The design ensures that each environment can be created, activated, and destroyed independently without side effects or interference.

---

## **2. Concept Overview**

A _bootstrapping tool_ is used to create a minimal standalone environment containing:

- A specific version of Python, and
    
- One or more package managers (e.g., Conda, Mamba, or both).
    

Once created, this environment is self-sufficient and can be activated using a simple script.  
All further management (installing, updating, exporting packages) is handled by the package manager _within_ the environment.

### **Why Micromamba**

Micromamba is a single, dependency-free executable designed for bootstrapping Conda-based environments.  
It provides the same functionality as Conda and Mamba for environment creation and package installation but does not require an existing Python installation.

However, its default behavior — particularly the `shell init` and `shell hook` mechanisms — introduces complications on Windows, including:

- Hardcoded absolute paths in generated scripts;
    
- Registry modifications (via `AutoRun`) affecting all future `cmd.exe` sessions;
    
- Non-portable activation logic relying on parent shell state.
    

These issues can be circumvented entirely by not initializing the shell at all.  
Instead, all necessary environment variables are configured explicitly by a custom bootstrap script.

---

## **3. Implementation**

The provided batch script, `Micromamba_bootstrap.bat`, acts as a _deterministic environment constructor_.  
It downloads and initializes Micromamba in a designated empty directory, then builds the target Python environment with minimal side effects.

### **Core Workflow**

1. **Download Micromamba (if not present)**  
    The script retrieves the latest binary from the official release channel.
    
    ```batch
    curl -L -o "%TMP%\micromamba.exe" ^
      https://micro.mamba.pm/api/micromamba/win-64/latest
    ```
    
2. **Create a new environment**
    
    ```batch
    micromamba.exe create -p "%TARGET_ENV%" python=3.12 mamba
    ```
    
    The environment is fully self-contained under `%TARGET_ENV%`.
    
3. **Activate environment manually**  
    The activation script sets `PATH` and `MAMBA_*` variables explicitly, avoiding any persistent shell hooks.
    

### **Key Design Choices**

- **Isolation:** no global variables or registry entries are modified.
    
- **Portability:** absolute paths in activation scripts are avoided.
    
- **Simplicity:** uses only `cmd.exe` batch syntax — no PowerShell dependency.
    
- **Determinism:** environment can be reproduced entirely from script and version specifications.
    

---

## **4. Workflow and Usage**

The recommended usage pattern involves two stages:

1. **Bootstrap phase:**
    
    ```batch
    Micromamba_bootstrap.bat my_env 3.12
    ```
    
    Creates a standalone environment containing Python 3.12 and Mamba.
    
2. **Operational phase:**  
    After activation, all subsequent management is handled via Conda/Mamba:
    
    ```batch
    mamba install numpy scipy
    ```
    
    The bootstrapping tool is no longer used beyond this point.
    

### **Environment Activation**

Instead of `micromamba activate`, which requires shell initialization, the script generates activation commands equivalent to:

```batch
micromamba.exe shell activate --shell cmd.exe -p "%ENV_PATH%"
```

The output is parsed to extract required environment variables and apply them in the current session.

### **Observed Behavior**

Testing revealed several nuances in Micromamba’s activation handling:

- Activation via `.exe` fails unless the shell is initialized.
    
- Activation via `.bat` succeeds, as it sets `MAMBA_ROOT_PREFIX` automatically.
    
- Directory order in `PATH` determines which tool variant (`.exe` or `.bat`) is resolved first.
    

---

## **5. Environment Notes**

### **5.1 Directory Layout**

The resulting environment follows the standard Conda-based layout.  
Essential directories include:

- **`<env_root>\python.exe`** — the interpreter;
    
- **`<env_root>\condabin`** — `.bat` wrappers for Conda, Mamba, and Micromamba (if shell hook is invoked);
    
- **`<env_root>\Scripts`** — auxiliary executables (including `conda.exe`);
    
- **`<env_root>\Library\bin`** — location of `mamba.exe` in recent versions.
    

No nonstandard directories are introduced by the bootstrap process.

---

## **Appendix A: Script Overview**

### **A.1 `Micromamba_bootstrap.bat`**

**Purpose:**  
Bootstraps a self-contained Python environment using Micromamba without relying on shell initialization.

**Key Mechanisms:**

- Detects and validates arguments (`env_name`, `python_version`).
    
- Downloads Micromamba if missing.
    
- Creates environment and ensures activation scripts are clean and portable.
    
- Emits clear error messages for network or path issues.
    

**Example snippet:**

```batch
if "%~1"=="" (
  echo Usage: %~nx0 [env_name] [python_version]
  exit /b 1
)
set ENV_DIR=%~dp0%~1
```

---

### **A.2 `get_sed.bat`**

**Purpose:**  
Utility script that ensures a standalone Windows-compatible `sed` binary is available, used by the main bootstrapper for text processing (e.g., patching environment files).

**Mechanisms:**

- Downloads and extracts GNU `sed` from an archive if not already installed.
    
- Handles basic integrity checks (existence, checksum if applicable).
    

**Example snippet:**

```batch
if not exist "%TOOLS%\sed.exe" (
  curl -L -o "%TMP%\sed.zip" %SED_URL%
  tar -xf "%TMP%\sed.zip" -C "%TOOLS%"
)
```

**Interdependency:**  
`Micromamba_bootstrap.bat` calls `get_sed.bat` when patching activation-related scripts for portability.

---

## **Appendix B: Design Notes and Improvements**

**Robustness:**  
The workflow deliberately avoids modifying global shell settings or registry entries, ensuring reproducibility and minimal side effects.

**Portability:**  
Since paths are handled dynamically and Micromamba is downloaded locally, the same scripts operate correctly across different drives or directory hierarchies.

**Possible Enhancements:**

- Integrate checksum validation for downloaded binaries.
    
- Add argument parsing for extended customization (channels, packages).
    
- Provide optional PowerShell variant for advanced scripting environments.
    

---

**End of Document**  
_(Full script listings are available in the repository.)_

---

Would you like me to produce a short **one-paragraph “About this project” section** (for GitHub repo top or bottom), summarizing its scope and intent in one or two sentences? It would serve as the concise project tagline.