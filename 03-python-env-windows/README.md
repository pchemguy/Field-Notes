# Python environments on Windows: Bootstrapping (via Micromamba) and Management (conda/mamba)

Python environments are a standard approach of managing specific version requirements for different applications. Usually, there is a top-level system-wide Python installation, which can be used for setting up virtual environments composed of specific versions of packages. Once the environment is set, it can be "activate", which is essentially replacing relevant environment variables in the child shells to point to the specific Python environment, instead of the system one. While this approach is a de-facto standard, it is fragile. Personally, I prefer a modified approach. While Linux distros commonly have a system Python installed, Windows does not. Python can be installed as a system-level application on Windows with system-wide "activation", similar to Linux, but I never do it. My approach is never having a system-level Python installation or global environment variables pointing to such an installation. Instead, each Python environment is standalone. All such environments are equal in role (no master environment); each environment is activated from a "clean" shell that does not have any pre-activated Python environment. With this design, the possibility that the shell might accidentally use a wrong environment is greatly reduced. The Path environment variable in any shell instance will either contain no references to any Python environments (baseline system environment) or a reference to a single activated environment. If activation process / scripts are corrupted, the application may not find the target Python environment and will fail rather loudly. However, when there is a second (system) Python environment referenced in Path and the process relies on Path resolution order to prioritize a custom activated environment over the system one, any issues with the custom environments, activation process, or even directory order in the Path, may result in application falling back to accessible system environment instead of failing with a bang, potentially causing subtle difficult to troubleshoot errors or misbehavior.

As my preferable Python ecosystem is Conda-based, ideally, I would like to have a compact lean standalone tool that does not rely on Python and permits convenient scripted bootstrapping of a minimal custom environments that would include a specific Python version and standard Conda/Mamba package managers. Once this environment is bootstrapped, the bootstrapping tool could activate it, and call subsequent scripts for installing the necessary packages using conda/mamba from the activated environment.

While there are several alternative installers for bootstrapping Conda-based Python environment, Micromamba is exactly as described, a single standalone executable suitable for bootstrapping Python environments. The [official project](https://github.com/mamba-org/mamba) does provide [binaries](https://github.com/mamba-org/micromamba-releases) and some [documentation](https://mamba.readthedocs.io/en/latest/installation/micromamba-installation.html) for the Windows environment. Unfortunately, there are a number of issues with the tool, scripts, and documentation. These issues are not critical and can be managed. The primary difficulty is to identify them and devise appropriate workarounds. The two primary general-use administrative scripting environments on Windows are `cmd.exe` and a more recent `PowerShell`.  I will solely rely on former for automating micromamba workflows.

[Micromamba releases repo](https://github.com/mamba-org/micromamba-releases) includes two installation scripts for Windows - `install.bat` for `cmd.exe` and `install.ps1` for `PowerShell`. Clearly, nobody has ever bothered running the `install.bat` script, as even a good LLM will identify syntactic errors that would prevent the script from running, let alone accomplishing any goals. `micromamba.exe` can be downloaded using `curl` following a general workflow described in installation scripts. The natural place for this module is the `Scripts` subdirectory within the target environment (this directory generally houses executables of installed package managers (conda, mamba, pip, wheel, etc.)), so the bootstrapping script should create this subdirectory and copy `micromamba.exe` into it. Micromamba is a subproject of the Mamba project. The official documentation does references Micromamba, but provides virtually no guidance, except for referencing the parent project. The general workflow with `Mamba` involving an existing environment, which is essentially a directory that holds (or will hold) the target environment, starts with environment activation.

An attempt to execute `micromamba.exe activate <PREFIX>` (as indicated by `micromamba.exe activate --help`) resulted in an error

```
critical libmamba Shell not initialized

'micromamba' is running as a subprocess and can't modify the parent shell.
Thus you must initialize your shell before using activate and deactivate.

To initialize the current  shell, run:
    $ eval "$(micromamba.exe shell hook --shell )"
and then activate or deactivate with:
    $ micromamba activate
To automatically initialize all future () shells, run:
    $ micromamba shell init --shell  --root-prefix=~/.local/share/mamba
If your shell was already initialized, reinitialize your shell with:
    $ micromamba shell reinit --shell
Otherwise, this may be an issue. In the meantime you can run commands. See:
    $ micromamba run --help

Supported shells are {bash, zsh, csh, posix, xonsh, cmd.exe, powershell, fish, nu}.
```

Note, how this help messages fails to provide proper command templates. The bottom line indicates supported options that must be provided after `--shell`. So, for example, the third option should read something like:

```
micromamba shell init --shell {SUPPORTED_SHELL} --root-prefix=~/.local/share/mamba
```

or, for `cmd.exe`: `micromamba shell init --shell cmd.exe --root-prefix=~/.local/share/mamba`. This command should be used with caution and, in fact better be avoided altogether.

The `init` command performs several actions.
1. First of all, it checks if long file paths are enabled. If not, it may include additional error information regarding this feature and request elevated execution to enable it. 

> [!NOTE]
> 
> Long file paths can be enabled directly via `regedit.exe`  or `reg.exe`:
> 
> ```reg
>[HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\FileSystem]
>"LongPathsEnabled"=dword:00000001
>```

2. The second actions involves generation of activation shell scripts in `{PREFIX}\Scripts` and `{PREFIX}\condabin`.
3. The final identified action is creation of registry setting:

```
[HKEY_CURRENT_USER\SOFTWARE\Microsoft\Command Processor]
"AutoRun"="G:\dev\Anaconda\envs\py\condabin\mamba_hook.bat"
```

The `AutoRun` script is executed for every new instance of the `cmd.exe` shell. Even if this script was actually working, having such `AutoRun` would be a very bad idea. But, as it turns out, this script does not work.

