# **Bootstrapping and Managing Python Environments on Windows (via Micromamba)**

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

## **Background and Motivation**

Traditional Python environment management assumes a system-level Python installation that serves as the base interpreter for user-created virtual environments.  
While this is a common practice, it introduces several fragility points:

- Environment activation relies on environment variable inheritance (`PATH`, `PYTHONPATH`), which can inadvertently reference the wrong interpreter.
- Misordered `PATH` entries may cause silent fallback to system installations rather than failing loudly.
- Shell initialization files or activation hooks may persist undesired configurations across sessions.

An alternative workflow can be readily followed on Windows, which does not integrate a system-level Python environment. This workflow described here adopts a more isolated and deterministic approach:

- **No system-wide (root/base) Python installation** - every environment is self-contained.
- **At most one environment per shell** - each shell session is either clean or linked to exactly one environment.
- **No Python environment switching in spawn child shells.**
- **No persistent shell hooks or autorun modifications.**

The design ensures that each environment can be created, activated, and destroyed independently without side effects or interference.

## **Why Micromamba**

A _bootstrapping tool_ is used to create a minimal standalone environment containing:
- A specific version of Python, and
- One or more package managers (e.g., Conda and Mamba for Conda ecosystem).

Once created, this environment is self-sufficient and can be activated using a simple script, calling on standard scripts provided by package managers.  
All further management (installing, updating, exporting packages) is handled by the package manager _within_ the environment.

Micromamba is a single, dependency-free executable designed for bootstrapping Conda-based environments.  
It provides the same functionality as Conda and Mamba for environment creation and package installation but does not require an existing Python installation.

However, its default behavior - particularly the `shell init` and `shell hook` mechanisms - introduces complications on Windows, including:
- Registry modifications (via `AutoRun`) affecting all future `cmd.exe` sessions;
- Non-portable activation logic relying on parent shell state.
- Hardcoded absolute paths in generated scripts;    

These issues can be circumvented entirely by not initializing the shell at all. Instead, all environment variables necessary for new Python environment creation are configured explicitly by a custom bootstrap script.

## **Core Workflow and Usage**

The provided batch script, `Micromamba_bootstrap.bat`, acts as a _deterministic environment constructor_. It downloads Micromamba, if unavailable, then builds the target Python environment in a designated empty directory with minimal side effects. The recommended usage pattern involves two stages:

**1. Bootstrap phase:**    
   The bootstrapping tool is called once to create a standalone environment containing Python 3.12, Mamba, and Conda:

```batch
Micromamba_bootstrap.bat my_env 3.12
```

   This call translates into the following core steps:

- **Download Micromamba (if not present)**  
    The script retrieves the latest binary from the official release channel.
- **Create a new environment**
    A fully self-contained environment is initialized under `%ENV_PREFIX%` `micromamba.exe create -p "%ENV_PREFIX%" python=3.12 mamba conda`
- **Activate environment by calling a standard script**  

**2. Build and operational phase:**  
    Subsequent installation of required packages is performed by a script placed in a user subdirectory within the new environment. Such a script can use a relative path to activate environment by calling standard *conda.bat* or *mamba.bat* wrappers. After activation, all subsequent management is handled via Conda/Mamba.

**Key Design Choices**
- **Isolation:** no global variables or registry entries are modified.
- **Simplicity:** uses only `cmd.exe` batch syntax - no PowerShell dependency.
- **Determinism:** environment can be reproduced entirely from script and version specifications.

## **Notes**

1. The *micromamba.exe* is called only once directly from *Micromamba_bootstrap.bat* without any required initialization to create a minimalistic, self-contained environment.
2. While *conda.bat* script is portable, Mamba/Micromamba generate *mamba.bat* script with hardcoded absolute paths, which is a poor coding practice. *Micromamba_bootstrap.bat* attempts to patch this script, though there are more files in the bootstrapped environment with hardcoded absolute paths, so actual portability of such an environment is unclear. 
3. Attempts to use *micromamba.exe* for environment activation failed persistently even after calling the *mamba_hook.bat* script per documentation, because the latter does not set the *MAMBA_ROOT_PREFIX* variable (as opposed to *mamba.bat* created by Micromamba *shell hook* command).
4. Beware that within an activate shell environment, both binaries (*conda.exe* and *mamba.exe*) and associated script wrappers (*conda.bat* and *mamba.bat*), providing important additional functionality, are in the *Path*. Because package management is usually performed without including executable extension, the actual module used (binary vs. script wrapper) is determined by *Path* order and *Path* resolution protocol. Wrappers will be used if their containing directory *({env_root}/condabin)* comes in the *Path* earlier than the binaries directory (*{env_root}\Scripts* or *{env_root}\Library\bin*).

