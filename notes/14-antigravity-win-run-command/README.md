# Running Antigravity App on Windows without PowerShell

## Problem Statement

In the Google Antigravity desktop application on Windows, the internal `run_command` execution harness is hard-coded to invoke commands through PowerShell:

```text
powershell -Command "<CLI>"
```

In environments where PowerShell (`powershell.exe` / `pwsh`) is absent, disabled, or excluded from `%PATH%`, the runtime fails immediately:

```text
exec: "<Cwd>\powershell": executable file not found in %PATH%
```

Furthermore, passing double quotes within `<CLI>` is prone to escape and parsing failures across the Go-to-batch execution boundary.

---

## Solution: `PowerShell.cmd` Shim

Because Windows command lookup evaluates `.cmd` files in `%PATH%` (and within the current working directory), creating a `PowerShell.cmd` shim intercepts the invocation and delegates execution to `cmd.exe`.

### Shim Implementation

Place the following script as `PowerShell.cmd` in a directory present in `%PATH%` (e.g., `~/.gemini/antigravity/bin`):

```bat
@echo off

set "CLI=%~2"
set "CLI=%CLI:'="%"

%CLI%
```

---

## How It Works

1. **Argument Extraction (`%~2`)**:
   The Antigravity backend executes `powershell -Command "<CLI>"`.
   - `%1` captures `-Command`.
   - `%~2` captures the CLI string while automatically stripping the surrounding outer double quotes added by the runner.

2. **Single-to-Double Quote Translation (`%CLI:'="%"`)**:
   Passing nested double quotes inside the agent's tool arguments frequently breaks parameter parsing in `cmd.exe`. 
   The shim translates single quotes (`'`) into standard Windows double quotes (`"`), allowing arguments containing spaces (e.g. paths like `'C:\Program Files'`) to be enclosed in single quotes by the caller and expanded cleanly for `cmd.exe`.

3. **Command Execution (`%CLI%`)**:
   Runs the unquoted, translated command line under `cmd.exe`.

---

## Caveats & Considerations

- **Global Single-Quote Replacement**: All single quotes in the command string are unconditionally replaced with double quotes. If a command or payload legitimately requires literal single quotes (e.g. specific regex patterns or Python one-liners), the shim will convert them to double quotes and would need to be adjusted or temporarily bypassed.