@echo off


REM Bootstrapping Python environment using Micromamba
REM   https://github.com/mamba-org/micromamba-releases
REM   https://github.com/mamba-org/mamba
REM   https://mamba.readthedocs.io/en/latest/installation/micromamba-installation.html
REM
REM -----------------------------------------------------------------------------
REM Usage:
REM   Micromamba_bootstrap.bat [ENV_NAME] [PY_VERSION]
REM     - It PY_VERSION is specified, the script will append PY_VERSION with dots
REM       replaced with underscrores to ENV_NAME.
REM     - The new environment is created under %~d0\dev\Anaconda\envs, unless
REM       PY_ENVS is defined, which will be used instead.
REM
REM Description:
REM   Creates a standalone, isolated Python environment managed by Micromamba.
REM   - If [ENV_NAME] is omitted, defaults to "py".
REM   - If [PY_VERSION] is omitted, installs the latest Python version.
REM -----------------------------------------------------------------------------
REM
REM Output:
REM   Installs Python + Mamba/Conda in %_ENV_PREFIX%.
REM   Reuses cached micromamba.exe if available in %~d0\CACHE.
REM   Automatically links package cache and patches hardcoded paths in mamba.bat.
REM -----------------------------------------------------------------------------
REM
REM NOTE:
REM   Micromamba used only for initial environment creation (Python + Mamba + Conda).
REM   After this, all operations use conventional mamba.bat or conda.bat wrappers.
REM -----------------------------------------------------------------------------


echo :========== ========== ========== ========== ==========:
echo  Bootstrapping Micromamba
echo :---------- ---------- ---------- ---------- ----------:

:: --------------------------------------------------------
:: Abort execution if Python-related environment variables are set.
:: --------------------------------------------------------
set "_CLEAN=1"
for %%V in (CONDA_PREFIX PYTHONHOME PYTHONPATH CONDA_SHLVL PYTHON_ENVS) do (
  if defined %%V (
    echo [WARN] %%V=%%V%%
    set "_CLEAN="
  )
)
if not defined _CLEAN (
  echo [ERROR] Detected active Python/Conda vars. Exiting...
  exit /b 1
)
set "_CLEAN="

:: --------------------------------------------------------
:: Check if specific Python version is requested.
:: --------------------------------------------------------
set _PY_V=%~2
if defined _PY_V (
  echo [INFO] Python version requested: "%_PY_V%".
) else (
  echo [INFO] Installing the latest Python version.
)


:: --------------------------------------------------------
:: Determine cache directory
:: --------------------------------------------------------
if exist "%~d0\CACHE" (
  echo [INFO] Using "%~d0\CACHE" cache directory.
  set _CACHE=%~d0\CACHE
) else (
  echo [INFO] Cache directory "%~d0\CACHE" does not exist. Will use TEMP instead.
  set _CACHE=%TEMP%
)

set _PKGS_DIR=%_CACHE%\Python\pkgs
if not defined CONDA_PKGS_DIRS (
  set CONDA_PKGS_DIRS=%_PKGS_DIR%
) else (
  set _PKGS_DIR=%CONDA_PKGS_DIRS%
)


:: --------------------------------------------------------
:: Determine base components of environment path
:: --------------------------------------------------------
if not "%~1"=="" (
  set _ENV_NAME=%~1
) else (
  set _ENV_NAME=py
)
if defined PY_ENVS (set _ENVS=%PY_ENVS%)
if not exist "%_ENVS%" (set _ENVS=%~d0\dev\Anaconda\envs)
if not exist "%_ENVS%" (set _ENVS=%CD%)

:: --------------------------------------------------------
:: If specific version of Python is requested, add suffix.
:: --------------------------------------------------------
set _PYTHON_PKG=python
if defined _PY_V (
    set _ENV_NAME=%_ENV_NAME%_%_PY_V:.=_%
    set _PYTHON_PKG=%_PYTHON_PKG%=%_PY_V%
)
set _PY_V=

set _ENV_PREFIX=%_ENVS%\%_ENV_NAME%
echo [INFO] Target environment path: "%_ENV_PREFIX%"
set _ENVS=
set _ENV_NAME=


:: --------------------------------------------------------
:: Abort if Python binary already in PREFIX
:: --------------------------------------------------------
if exist "%_ENV_PREFIX%\python.exe" (
  echo [ERROR] Found existing "%_ENV_PREFIX%\python.exe". Aborting bootstrapping...
  exit /b 1
)

if exist "%_ENV_PREFIX%" (
  echo [INFO] Deleting existing prefix directory.
  rmdir /S /Q "%_ENV_PREFIX%"
)


:: --------------------------------------------------------
:: Download Mamba
:: --------------------------------------------------------
set _RELEASE_URL=https://github.com/mamba-org/micromamba-releases/releases/latest/download/micromamba-win-64
set MAMBA_EXE=%_PKGS_DIR%\micromamba.exe
if exist "%MAMBA_EXE%" (
  echo [INFO] Using cached "%MAMBA_EXE%"
) else (
  echo [INFO] Downloading: %_RELEASE_URL%
  echo [INFO] Destination: %MAMBA_EXE%
  curl --fail --retry 3 --retry-delay 2 -L -o "%MAMBA_EXE%" "%_RELEASE_URL%"
  if not !ERRORLEVEL! equ 0 (
    echo [ERROR] Micromamba download failure. Aborting bootstrapping...
    exit /b 1
  )
)
set _RELEASE_URL=


:: --------------------------------------------------------
:: Create new Python environment
:: --------------------------------------------------------
echo [INFO] Creating new Python environment...
set PKGS=mamba conda uv %_PYTHON_PKG%
echo:
"%MAMBA_EXE%" create --yes --override-channels -c conda-forge --prefix "%_ENV_PREFIX%" %PKGS%
echo:
set _PYTHON_PKG=
set PKGS=

set CONDA_BIN=%_ENV_PREFIX%\condabin
set MAMBA_ROOT_PREFIX=%_ENV_PREFIX%
set MAMBA_BAT=%CONDA_BIN%\mamba.bat
set MAMBA_EXE=%_ENV_PREFIX%\Library\bin\mamba.exe

echo [INFO] MAMBA_ROOT_PREFIX: "%MAMBA_ROOT_PREFIX%"
echo [INFO] MAMBA_BAT: "%MAMBA_BAT%"
echo [INFO] MAMBA_EXE: "%MAMBA_EXE%"


echo [INFO] Set junction to package cache...
echo:
if exist "%_PKGS_DIR%" (
  if exist "%_ENV_PREFIX%\pkgs" rmdir /S /Q "%_ENV_PREFIX%\pkgs"
  mklink /j "%_ENV_PREFIX%\pkgs" "%_PKGS_DIR%"
)
set _PKGS_DIR=
echo:


:: --------------------------------------------------------
:: Patch absolute paths in mamba.bat and mamba_hook.bat
:: --------------------------------------------------------
echo [INFO] Optionally patch mamba.bat and mamba_hook.bat

echo [INFO] Obtain sed to patch absolute hardcoded paths.
where sed.exe 2>nul && (
  set SED=sed.exe
  goto :PATCH_SCRIPTS
)
if exist "%~dp0get_sed.bat" (
  call "%~dp0get_sed.bat" "%_CACHE%"
  if not !ERRORLEVEL! equ 0 (
    echo [ERROR] Sed download failure. Aborting patching...
    goto :SKIP_PATCHING
  )
  set "SED=%_CACHE%\sed\sed.exe"
)

:PATCH_SCRIPTS
echo [INFO] Patch absolute paths in mamba scripts
set _TARGET=%MAMBA_BAT%
set _DEL_MAMBA_EXE=/@SET \"MAMBA_EXE=.*\"/d

REM Carret enables splitting the line. \n enables multiline output.

set _PATCH_ENV_VAR=s#@SET .MAMBA_ROOT_PREFIX=.*#^
  set CUR_DIR=%%CD%%\n^
  cd /d \"%%~dp0..\"\n^
  set MAMBA_ROOT_PREFIX=%%CD%%\n^
  cd /d \"%%CUR_DIR%%\"\n^
  set CUR_DIR=\n^
  set MAMBA_EXE=%%MAMBA_ROOT_PREFIX%%\\Library\\bin\\mamba.exe#

"%SED%" -i.bak -e "%_DEL_MAMBA_EXE%" -e "%_PATCH_ENV_VAR%" "%_TARGET%"

set _TARGET=%CONDA_BIN%\mamba_hook.bat
set _PATCH_ENV_VAR=s#@SET .MAMBA_EXE=.*#@SET ""MAMBA_EXE=%%__mamba_root%%\\Library\\bin\\mamba.exe""#

"%SED%" -i.bak -e "%_PATCH_ENV_VAR%" "%_TARGET%"

set _DEL_MAMBA_EXE=
set _PATCH_ENV_VAR=
set _TARGET=
set SED=

:SKIP_PATCHING

:: --------------------------------------------------------
:: Activate new environments using Mamba
:: --------------------------------------------------------
echo [INFO] Activating Python environment - Mamba.
echo        MUST use mamba.bat wrapper, not mamba.exe directly.

call "%MAMBA_BAT%" activate
echo:
echo :========== ========== ========== ========== ==========:
call python.exe --version
echo :---------- ---------- ---------- ---------- ----------:
echo:
if not %ERRORLEVEL% equ 0 (
  echo [ERROR] Python environment failed to initialize.
  exit /b 1
)


:: --------------------------------------------------------
:: Copy scripts and configs
:: --------------------------------------------------------
cd /d "%~dp0..\.."
if exist "%CD%\__shortcut__" if not exist "%_ENV_PREFIX%\__shortcut__" (
    md "%_ENV_PREFIX%\__shortcut__"
    xcopy /H /Y /B /E /Q "%CD%\__shortcut__" "%_ENV_PREFIX%\__shortcut__"
)
if exist "%CD%\__home__" if not exist "%_ENV_PREFIX%\__home__" (
    md "%_ENV_PREFIX%\__home__"
    xcopy /H /Y /B /E /Q "%CD%\__home__" "%_ENV_PREFIX%\__home__"
)
if exist "%CD%\__AppData__" if not exist "%_ENV_PREFIX%\__AppData__" (
    md "%_ENV_PREFIX%\__AppData__"
    xcopy /H /Y /B /E /Q "%CD%\__AppData__" "%_ENV_PREFIX%\__AppData__"
)
