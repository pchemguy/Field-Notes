# Bootstrapping Python Environments on Windows

![Bootstrapping Python environments on Windows](vis.jpg)

I wanted each Windows project to have its own Python and package managers, with a plain Command Prompt usable before and after a build. Micromamba solved the first problem because its standalone executable can create a Conda environment at a chosen path before Python is installed. For the second, I use the environment’s own `conda.bat` to activate it in the CMD session that needs it.

On Windows, the [Conda Bootstrap CMD harness](https://github.com/pchemguy/Conda-Bootstrap#windows-harness) uses `Anaconda.bat` to build the environment and `conda_far.bat` to open it for everyday work. The [original single-script prototype](Micromamba_bootstrap.bat) is preserved here as a legacy artifact.

Conda Bootstrap also provides a **Linux variant for Bash**. From the directory containing the copied Linux harness, run `bash ./Anaconda.sh` to create the local `Anaconda/` environment, then `source ./Anaconda_activate.sh` to activate it in the current shell. [Linux setup and usage](https://github.com/pchemguy/Conda-Bootstrap#linux-harness)

## Background and Motivation

A common Windows setup starts with a machine-wide Python installation and uses it to create a virtual environment for each project. The problem I wanted to avoid was silent fallback. If activation leaves the wrong directory first on `PATH`, a build can still find `python.exe` and run successfully with the wrong interpreter. An inherited `PYTHONPATH` can also make the intended interpreter import modules from another project. Child processes inherit both settings.

Windows does not require a system Python. I can leave Python off the machine-wide `PATH`, start with a plain Command Prompt, and choose an interpreter for the project at hand.

- **One installation per project.** The project prefix contains Python, its package managers, and its dependencies. I can rebuild one project without replacing a shared base interpreter.
- **At most one environment per shell.** I start from a clean prompt and activate one project. The launcher stops if Conda is already active or if CMD can already find `python.exe` or `conda.bat`.
- **Child shells stay with the same project.** Build scripts and programs launched from the activated prompt inherit its environment. To work on a different project, I open a fresh prompt instead of switching environments in a child shell.
- **Activation is explicit.** I want opening CMD to leave the choice of project to me. The harness calls the project’s Conda wrapper when needed and requires no persistent Micromamba shell hook or CMD `AutoRun` entry.

Each project owns its installed environment. The harness shares downloads and package caches across projects, and Micromamba’s shell integration can leave files in the Windows user profile.

## Create the project environment

Copy the **contents** of the [Windows harness directory](https://github.com/pchemguy/Conda-Bootstrap/tree/main/windows) into the local directory that will hold the project environment. For example, with `Anaconda.bat` in `D:\Dev\MyProject`, the resulting interpreter is `D:\Dev\MyProject\Anaconda\python.exe`. Pick the final location before building because installed wrappers can contain absolute paths.

Edit the manifests beside `Anaconda.bat` before the first run.

| File | What to put in it |
| --- | --- |
| `Anaconda_bootstrap.yml` | Python and the base tools. To select Python 3.12, change the `python` entry under `dependencies` to `python=3.12`. The supplied base also includes Conda, Mamba, Micromamba, uv, and pytest. |
| `Anaconda.yml` | Conda project dependencies. The supplied manifest includes Node.js, NumPy, pandas, and Polars. |
| `Anaconda.txt` | Python requirements to install with uv after the Conda packages, including packages from PyPI or direct wheel URLs. |

**Before the first run**, check the pip and uv caches under `%LOCALAPPDATA%`. The harness replaces `pip\cache` and `uv\cache` with junctions to a shared cache, deleting the contents of existing ordinary directories at those paths. To choose the shared cache, set `_CACHE` to an existing writable directory.

> [!WARNING]
> In my CMD tests, `micromamba.exe shell hook -s cmd.exe` left scripts in `%APPDATA%\mamba`. If `micromamba.exe` prints nothing when run without arguments, check `echo %ERRORLEVEL%` immediately, move the directory aside if present, and retry. After its `--version` check succeeds, `Anaconda.bat` pauses before recursively deleting that directory if it exists. `/q` skips the pause.

On x64 Windows, open a Command Prompt with `curl.exe` and `tar.exe` available and no other Python or Conda installation on `PATH`. Run the bootstrap from the directory containing the copied files.

```bat
cd /d D:\Dev\MyProject
Anaconda.bat
```

The bootstrap downloads or reuses Micromamba and uv, then calls `micromamba.exe create` with the bootstrap YAML and an explicit prefix. It calls `conda_far.bat /preactivate` to activate that prefix and checks its Python. A full run applies `Anaconda.yml` with Mamba. It then processes any `*.req.txt` files with pip, followed by `requirements.txt` and `Anaconda.txt` with uv when present. It writes `Anaconda_generated.yml` (Conda export) and `Anaconda.pip.txt` (Python package list) beside the batch file and returns to the original prompt. The supplied manifests leave versions open, so a fresh solve can select newer packages.

Use `Anaconda.bat /init` for the base alone. Once `Anaconda\python.exe` exists, `Anaconda.bat` returns success immediately. That includes a base-only install or a run that failed after creating Python. To rebuild with the full manifests, move the old prefix aside and run the bootstrap again. [Windows bootstrap reference](https://github.com/pchemguy/Conda-Bootstrap/blob/main/windows/Anaconda.md)

## Work in the environment

From the local harness directory, run `conda_far.bat`. It activates `Anaconda\`, calls any sibling `config_*.bat` files, and starts FAR Manager if available or an interactive Command Prompt otherwise. In that session, check which interpreter your build will use.

```bat
python -c "import sys; print(sys.executable)"
```

For the example above, this prints `D:\Dev\MyProject\Anaconda\python.exe`. To run project commands from a batch file of your own, place it beside the launcher and use `/batch` so execution returns to your script with the environment active.

```bat
@echo off
setlocal EnableExtensions EnableDelayedExpansion
call "%~dp0conda_far.bat" /batch
if not "%ERRORLEVEL%"=="0" exit /b %ERRORLEVEL%
python --version
```

When the sibling `msbuild.bat` is present, the launcher asks it to detect and activate an installed x64 MSVC toolchain. If the tools cannot be found, activation stops and the helper points to installation instructions. Installation is manual. The separate [pip and MSVC field note](../05-python-pip-msvc/README.md) covers compiler discovery and the MSYS `link.exe` name collision. See the [launcher reference](https://github.com/pchemguy/Conda-Bootstrap/blob/main/windows/conda_far.md) for single-command execution and configuration hooks.

## Why I use the installed Conda wrapper

**Shell initialization and activation have different lifetimes.** In my original CMD tests, `micromamba shell init` could register an `AutoRun` command that affected subsequent Command Prompts. I also tried calling `mamba_hook.bat` directly. In the version I tested, it left `MAMBA_ROOT_PREFIX` unset, while the wrapper generated through `micromamba shell hook` set it. Creating a prefix with `micromamba.exe create` needs neither step. Once the prefix exists, the harness calls its `condabin\conda.bat` explicitly.

**The command name can hide which file CMD runs.** An active prefix can expose both `conda.bat` and `conda.exe`, or `mamba.bat` and `mamba.exe`. Their locations on `PATH` affect which one a bare command selects. That matters for activation because a batch wrapper can change the calling CMD environment. The harness calls the wrapper by path. In the earlier prototype I also tried rewriting absolute paths in generated Mamba wrappers with [a sed helper](get_sed.bat). The current harness uses the installed wrappers as supplied. If a project moves, rebuild its prefix at the destination.
