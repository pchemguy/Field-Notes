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

Note, how this help messages fails to provide proper command templates. The bottom line indicates supported options that must be provided after `--shell`. So, for example, the third option should read something like (the prefix example is for `bash` and left as is):

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

The `AutoRun` script is executed for every new instance of the `cmd.exe` shell. Having such `AutoRun` is a very bad idea.

The vague first option should be executed as 

```
shell hook --shell cmd.exe --root-prefix={PREFIX}
```

This command is supposed to be used as part of the portable mode. It creates the same scripts and instructs to execute the same `mamba_hook.bat` script before activating environment.

An important note is that the `init`/`hook` commands create, among other scripts, `micromamba.bat`. If we check the Windows-related [installation section](https://mamba.readthedocs.io/en/latest/installation/micromamba-installation.html#windows), the first part involving installation and initialization refers to `micromamba.exe`, while environment management lines do not include extension, meaning they could refer to either `.exe`  or `.bat`. This peculiarity on it own does not provide substantial information, considering the overall lacking Windows-related documentation (both in quantity and quality). Still, having a shell script wrapping the associated manager educatable to provide additional functionality is a common approach also employed by both `Mamba` and `Conda`. For `Mamba` and `Conda`, the `.exe` files are placed in the `{PREFIX}\Script` directory, whereas the `.bat` scripts are placed in the `{PREFIX}\condabin` directory by the installers (`micromamba.bat` is created here as well). This is an important consideration because both of these directories are added to `Path` when a conda-based environment is activated. If extension is omitted, which is a standard approach, shell will have to select between `.exe` and `.bat` using the conventional resolution protocols. The `.bat` files are generally designed in a manner such that any command line functionality provided by `.exe` files should be also transparently available when calling associated `.bat`. If environment activation process is amended, the calling script should ensure that `{PREFIX}\condabin` with `.bat` appears before `{PREFIX}\Script` with `.exe`.

As far as `Micromamba` is concerned, attempt to perform basis operation (environment activation) failed repeatedly, when executed directly on `micromamba.exe`, resulting in repeated complains about shell not being properly initialized (meaning either missing/misset environment variables and/or missing essential command line defaults taken care of by the associated shell script code). At the same time, calling `micromamba.bat` worked just fine. Additionally, all the default `mamba_hook.bat` script (supposed to be called for environment initialization) does, is prepending `condabin` directory to the `Path` variable and setting `MAMBA_BAT` and `MAMBA_EXE` variables. `micromamba.bat` also sets `MAMBA_EXE`, but also `MAMBA_ROOT_PREFIX` before calling `micromamba.bat`. Apparently, `MAMBA_ROOT_PREFIX` missing from `mamba_hook.bat` was the reason why calling `micromamba.exe` directly after calling `mamba_hook.bat` failed. While I imagine that some extensions might use the hook file for additional settings, the basic setting in the default file can be set in the bootstrapping script instead.

Another important command

```
micromamba.exe shell activate --shell cmd.exe -p {PREFIX}
```

generates activation environment (not including `MAMBA*` variables), for example

```batch
@echo off

set CLI=micromamba.exe shell activate --shell cmd.exe -p "%~dp0.."
for /f "usebackq tokens=1,* delims=" %%G in (`%CLI%`) do (
  set ENV_FILE=%%~G
)

for /f "usebackq tokens=1,* delims==" %%G in ("%ENV_FILE%") do (
  set VAR=%%G
  set DAT=%%H
  echo !VAR!=!DAT!
)
```

Examination of the output of this command shows that the `activate` command prepends Python related directories to Path, placing the "condabin" directory *after* "Script".  If `mamba_hook.bat` is executed before the `activate` command,  directory with `micromamba.bat` will appear in the Path first and `micromamba activate` command would be properly resolved. However, after this command, Path is updated again, placing `micromamba.exe` directory first. At the same time, it appears that for other environment management commands, executed after activation, the difference between execution of `.exe` and `.bat` may not be important. Still, it might be a good idea to keep this matter in mind.

Also note that some of the generated scripts use hardcoded absolute paths instead of proper portable relative references.
