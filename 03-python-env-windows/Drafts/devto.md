---
title: "Bootstrapping Python on Windows with Micromamba"
published: true
description: "A clean, deterministic way to build Python environments on Windows without shell hooks, registry edits, or broken installers. Use Micromamba only for what it does best."
tags: ["python", "windows", "mamba"]
cover_image: "https://raw.githubusercontent.com/pchemguy/Field-Notes/refs/heads/main/03-python-env-windows/visw.jpg"
canonical_url: "https://github.com/pchemguy/Field-Notes/blob/main/03-python-env-windows/README.md"
---

Managing Python on Windows can feel like walking through quicksand. Between global installs, conflicting `PATH` entries, and "smart" shell hooks that modify your registry, things get messy fast.

This post documents a cleaner alternative. The workflow uses a standalone tool, [Micromamba](https://github.com/mamba-org/micromamba-releases), and a simple batch script to create Conda-based environments that are lightweight, deterministic, and transparent. It avoids shell initialization, activation hooks, and registry pollution entirely.

The key insight? Don't let Micromamba handle activation or initialization. Just let it do the one thing it excels at: creating environments.

The result is a simple `cmd.exe` workflow that is:
- ✅ **Explicit:** Every step is clear and inspectable.
- ✅ **Isolated:** No registry edits or global state changes.
- ✅ **Reproducible:** Build and tear down identical environments every time.
- ✅ **Simple:** No dependency on PowerShell or complex tooling.

---

### The Core Idea 💡

Use `micromamba.exe` once to bootstrap a self-contained environment. For all other tasks - installing packages, activation, etc. - use the standard `conda` or `mamba` commands that now live *inside* that new environment. No shell hooks, no registry edits, no magic.

## The Problem with "Smart" Setups

Typical Python setups on Windows rely on a system-wide interpreter and shell-level magic, which introduces several points of failure:
- Activation depends on inherited `PATH` and `PYTHONPATH` variables.
- One wrong entry in your `PATH` and scripts can silently use the wrong Python interpreter.
- Shell hooks (`shell init`) can persist unwanted settings across sessions by modifying the registry.
- Uninstalling often leaves clutter behind.

My approach flips the model by enforcing a stricter, cleaner separation:
- No global Python installation.
- Each shell session is linked to at most one environment.
- Never switch environments - use clean shell for activation.
- No persistent shell hooks or `AutoRun` modifications.

Each environment becomes a sealed unit you can create, activate, and destroy with zero side effects.

## The Right Tool for the Job

Micromamba is a good tool for this workflow. It is a compact, standalone binary perfect for creating Conda environments without needing an existing Python installation.

However, its shell integration features can be problematic on Windows:
- The official `install.bat` script is broken.
- `micromamba shell init` modifies registry `AutoRun` entries, affecting every `cmd.exe` session.
- It generates scripts with hard-coded absolute paths, making environments less portable.

Environment activation via `micromamba.exe activate` failed repeatedly even after calling the `mamba_hook.bat` script in accordance with the documentation, because `mamba_hook.bat` does not set the `MAMBA_ROOT_PREFIX` variable.

I sidestep these issues entirely. Instead of fighting Micromamba's shell management, I do not use it at all. The bootstrap script calls `micromamba.exe` only once to build the environment. After that, I can use the robust tools (Mamba and Conda) installed *inside* the environment.

## The Bootstrap Workflow

### Step 1: Bootstrap the Environment

Run the bootstrap script from your terminal to create a new, self-contained environment.

```batch
Micromamba_bootstrap.bat my_env 3.12
```

This single command performs several actions:

**1.** Downloads the `micromamba.exe` binary if it is missing.  
**2.** Creates a new, self-contained environment with Python, Mamba, and Conda via the `create` command.

```
micromamba.exe create -p "%ENV_PREFIX%" python=3.12 mamba conda
```
  
**3.** Activates the new environment once to verify its integrity.

Your new environment is now ready at a path like `DRIVE:\path\to\envs\my_env_3_12`, complete with `python.exe`, `mamba.exe`, and `conda.exe`.

### Step 2: Use the Environment

With the environment created, you manage it using the standard Mamba or Conda commands from within its `condabin` directory.

```
call "%ENV_PREFIX%\condabin\mamba.bat" activate
mamba install numpy scipy
```

No tricky commands, no hidden hooks. Just a clean environment that works as expected.

## Final Words

This approach provides a controlled and reproducible method for bootstrapping Python environments on Windows. By keeping the logic explicit and avoiding shell-level modifications, you get a robust setup that is easy to manage, version, and share. You can find the annotated `Micromamba_bootstrap.bat` script and additional information in the [project's GitHub repository](https://github.com/pchemguy/Field-Notes/tree/main/03-python-env-windows).
