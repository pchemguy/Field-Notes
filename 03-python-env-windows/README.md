# **Bootstrapping Python Environments on Windows**

![](https://raw.githubusercontent.com/pchemguy/Field-Notes/refs/heads/main/03-python-env-windows/vis.jpg)

This document describes a simplified and reproducible workflow for initializing Conda-based Python environments on Windows **without relying on shell initialization or automatic activation**. The approach focuses on transparent environment construction, deterministic behavior, and compatibility with standard Python tools. The presented method eliminates issues related to Micromamba’s shell hook logic and implicit state persistence while maintaining a lightweight structure. All essential actions - environment creation, configuration, and activation - are performed through explicit commands defined in dedicated batch scripts.

The repository contains:
- Two annotated batch scripts implementing the described workflow:  
    - [Micromamba_bootstrap.bat](https://github.com/pchemguy/Field-Notes/blob/main/03-python-env-windows/Micromamba_bootstrap.bat)
    - [get_sed.bat](https://github.com/pchemguy/Field-Notes/blob/main/03-python-env-windows/get_sed.bat)
- This README, providing background, design notes, and usage documentation.
- Drafts and raw discovery/exploration notes containing broader or more technical details not currently included in the main text.

Together, these materials form a concise reference implementation for controlled Micromamba-based environment bootstrapping on Windows.

## **Background and Motivation**

Traditional Python environment management assumes a system-level Python installation that serves as the base interpreter for user-created virtual environments.  
While this approach is common, it introduces several fragility points:
- Environment activation relies on environment variable inheritance (`PATH`, `PYTHONPATH`), which can inadvertently reference the wrong interpreter.
- Misordered `PATH` entries may cause silent fallback to system installations rather than failing loudly.
- Shell initialization files or activation hooks may persist undesired configurations across sessions.

An alternative workflow can be applied on Windows, which does not integrate a system-level Python environment. The workflow described here adopts a more isolated and deterministic approach:
- **No system-wide (root/base) Python installation** - every environment is self-contained.
- **At most one environment per shell** - each shell session is either clean or linked to exactly one environment.
- **No environment switching in spawned child shells.**
- **No persistent shell hooks or autorun modifications.**

This design ensures that each environment can be created, activated, and destroyed independently without side effects or interference.

## **Why Micromamba**

The primary objective is to use a command line bootstrapping tool to create a minimal standalone environment containing:
- A specific (or latest by default) version of Python.
- One or more package managers (e.g., Conda and Mamba within the Conda ecosystem).

Once created, this environment is self-sufficient and can be activated via standard scripts provided by the package managers. All subsequent package management operations (installing, updating, exporting) are handled within the environment itself.

Micromamba is a single, dependency-free executable designed for bootstrapping and managing Conda-based environments. It provides the same functionality as Conda and Mamba for environment creation and package installation but does not require an existing Python installation.

However, the official Windows-related Micromamba documentation is lacking, while the provided installation script, `install.bat`, is broken. Further,
Micromamba's default behavior - particularly the `shell init` and `shell hook` mechanisms - introduces complications on Windows, including:
- Registry modifications (via `AutoRun`) that affect all future `cmd.exe` sessions.
- Non-portable activation logic relying on parent shell state.
- Hard-coded absolute paths in generated scripts.

These issues can be completely avoided by not initializing the shell at all. Instead, a custom bootstrap script uses *micromamba.exe* for creation of the new environment - the process not requiring any mandatory environment configuration, though `CONDA_PKGS_DIRS` should be set to point to package cache directory.

## **Core Workflow and Usage**

The provided batch script, `Micromamba_bootstrap.bat`, acts as a deterministic environment constructor. It downloads Micromamba (if unavailable) and then builds the target Python environment in a designated empty directory with minimal side effects. The recommended usage pattern involves two stages:

### **1. Bootstrap phase**

The bootstrap script is called once to create a standalone environment containing Python (for example, 3.12, optional), Mamba, and Conda:

```batch
Micromamba_bootstrap.bat my_env 3.12
```

This call performs the following key steps:
- **Download Micromamba (if not present)**  
    Retrieves the latest binary from the official release channel.
- **Create a new environment**  
    Initializes a self-contained environment under `%ENV_PREFIX%` via `micromamba.exe create -p "%ENV_PREFIX%" python=3.12 mamba conda`  
- **Activate the environment**  
    Calls a standard script (e.g., `conda.bat`) to enable the environment.

### **2. Build and operational phase**

Subsequent installation of required packages is performed by user scripts placed within the new environment. Such scripts can use relative paths to activate the environment via standard `conda.bat` or `mamba.bat` wrappers. After activation, all management tasks (install, update, export) are handled using Conda or Mamba within the active environment.

## **Notes**

1. `micromamba.exe` is called only once directly from `Micromamba_bootstrap.bat` without shell initialization to create a minimal self-contained environment.
2. While `conda.bat` is portable, Mamba/Micromamba generate `mamba.bat` with hard-coded absolute paths, reducing portability. The bootstrap script attempts to patch this script, but other hard-coded paths remain, so full portability is not guaranteed.
3. Attempts to use `micromamba.exe` for activation failed persistently, even when invoking `mamba_hook.bat` as documented. The latter does not set `MAMBA_ROOT_PREFIX`, unlike `mamba.bat` generated by the `micromamba shell hook` command.    
4. Within an active environment, both binaries (`conda.exe`, `mamba.exe`) and script wrappers (`conda.bat`, `mamba.bat`) are on the `PATH`. Since commands are typically called without an extension, the module used (binary vs. wrapper) depends on `PATH` order and resolution. Wrappers will take precedence if their directory (`{env_root}\condabin`) appears before binary directories (`{env_root}\Scripts` or `{env_root}\Library\bin`).

>[!WARNING]
>
>`micromamba.exe` may fail silently (when executed without any arguments, it should normally produce usage information in console) if `micromamba.exe shell hook -s cmd.exe` is executed (no console output is produced at all, though %ERRORLEVEL% should be set to non-zero value). This command creates a directory `%APPDATA%\mamba` with scripts. These scripts are not needed for creating environment. If silent failure is observed, make sure to delete `%APPDATA%\mamba`, if exists.

## **Summary and Outlook**

The presented workflow provides a controlled and reproducible method for bootstrapping Conda-based Python environments on Windows without relying on shell initialization or persistent configuration. By consolidating all environment setup logic into explicit, script-driven commands, it ensures predictable, self-contained operation while avoiding the side effects of Micromamba’s shell hooks.

This approach emphasizes:
- **Transparency:** all steps are explicit and inspectable.
- **Simplicity:** implemented entirely in `cmd.exe` batch syntax, without PowerShell dependency.
- **Isolation:** no global variables or registry entries are modified.
- **Reproducibility:** identical environments can be reconstructed from the same script and version inputs.
- **Portability:** environments remain largely relocatable and independent of system configuration.
- **Robustness:** no hidden dependencies on global state or transient shell settings.

While the current implementation fully addresses the initialization and activation stages, further refinements could improve portability by eliminating residual absolute paths and adding sample scripts for subsequent environment building or activation - though these processes rely entirely on standard workflows of conventional package managers.
