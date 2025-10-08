---
title: "Bootstrapping Python Environments on Windows - with Micromamba (the right way)"
published: true
description: "A clean, deterministic way to build Python environments on Windows without shell hooks, registry edits, or broken install scripts - using Micromamba only for what it does best."
tags: ["python", "windows", "devtools", "conda", "automation"]
cover_image: "https://raw.githubusercontent.com/pchemguy/Field-Notes/refs/heads/main/03-python-env-windows/vis.jpg"
canonical_url: "https://github.com/pchemguy/Field-Notes"
---

> A reproducible, shell-free, and frustration-proof approach to creating Python environments on Windows using **Micromamba**, **Conda**, and **Mamba** - without breaking your shell or touching your registry.

---

Managing Python on Windows often feels like walking through quicksand.  
Between global installs, conflicting PATH entries, and “smart” shell hooks that modify your registry, things get messy fast.

This post documents a cleaner alternative I arrived at through a long (and occasionally painful) exploration process.  
The key insight: don’t let Micromamba handle activation or initialization at all - just let it do the one thing it’s really good at: *creating environments*.

The result is a simple `cmd.exe` workflow that’s:
- 100% explicit
- PowerShell-free
- Portable and reproducible
- Easy to tear down and rebuild at any time

---

# 🧱 TL;DR

👉 Use Micromamba only once - to create your environment.  
👉 Use Mamba or Conda for everything else.  
👉 No hooks. No registry edits. No headaches.

---

# 🐍 Bootstrapping Python Environments on Windows - _with Micromamba_

![](https://raw.githubusercontent.com/pchemguy/Field-Notes/refs/heads/main/03-python-env-windows/visw.jpg)

Managing Python environments on Windows can get messy - especially when tools try to “automate” shell setup behind your back.  
If you’ve ever fought with broken activations, registry pollution, or path conflicts, this post is for you.

This writeup presents a lightweight, deterministic, and fully transparent workflow for creating Conda-based environments on Windows _without any shell initialization or activation hooks_.  
Everything is done explicitly via a simple batch script - `Micromamba_bootstrap.bat`.

The result:  
A reproducible setup, no registry edits, no global Python installs, no mysterious state.

---

## ⚙️ Why Even Bother?

Typical Python setups rely on a system-wide interpreter. That is fine - until it is not.

Common pain points:
- Activation depends on inherited `PATH` and `PYTHONPATH`
- One wrong entry, and your script silently uses the wrong Python
- Shell hooks can persist unwanted settings across sessions
- Uninstallation leaves clutter in the registry

This workflow flips the model:
- No global Python install
- Exactly **one** environment per shell
- No persistent shell hooks
- No child-shell activation confusion

Each environment becomes a sealed unit: create, activate, destroy - zero side effects.

---

## 🚀 Enter Micromamba

Micromamba is a tiny, standalone binary - perfect for creating Conda environments without needing Python preinstalled.  
However… on Windows, it is not exactly plug-and-play:
- The official `install.bat` is broken    
- Documentation is confusing
- `micromamba shell init` messes with registry `AutoRun` entries
- Hard-coded paths make environments non-portable

So, instead of fighting those issues, I simply do not use Micromamba for shell management at all.

Instead, the bootstrap script calls `micromamba.exe` _once_ - to create the environment.  
After that, all management (install, update, export) happens via Mamba or Conda, safely inside the environment.

---

## 🧰 The Bootstrap Workflow

### Step 1: Create the Environment

Run the script once:

```batch
Micromamba_bootstrap.bat my_env 3.12
```

This does:  
- Downloads Micromamba if missing
- Creates a self-contained environment:
    
```
micromamba.exe create -p "%ENV_PREFIX%" python=3.12 mamba conda
```
    
- Optionally patches hardcoded paths inside generated scripts
- Activates the environment once to verify

After that, your new environment lives at something like:

```
<drive>\dev\Anaconda\envs\my_env_3_12\
```

…and includes `python.exe`, `mamba.exe`, and `conda.exe` - ready to go.

---

### Step 2: Use It Normally

Inside the new environment, you can manage packages just as usual:

```batch
call "%ENV_PREFIX%\condabin\mamba.bat" activate
mamba install numpy scipy
```

No special Micromamba commands.  
No hidden hooks.  
Just the environment you created.

---

## ✅ Key Advantages

- **Transparency:** every action is explicit and inspectable  
- **Isolation:** no registry writes or global variables
- **Reproducibility:** deterministic builds, minimal dependencies
- **Simplicity:** pure batch (`cmd.exe`) implementation
- **Portability:** mostly relocatable environments
