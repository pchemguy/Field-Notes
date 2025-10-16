@echo off


echo :========== ========== ========== ========== ==========:
echo  Bootstrapping Micromamba
echo :---------- ---------- ---------- ---------- ----------:


set  "INFO=[100;92m [INFO]  [0m"
set  "OKOK=[103;94m -[OK]-  [0m"
set  "WARN=[106;35m [WARN]  [0m"
set "ERROR=[105;34m [ERROR] [0m"


:: --------------------------------------------------------
:: BASE CONFIG
:: --------------------------------------------------------
set "YAML=%~n0"
if /I "%YAML:~-7%"=="_umamba" (set "YAML=%YAML:~0,-7%")
set "YAML=%~dp0%YAML%.yml"
if not exist "!YAML!" (
  echo %ERROR% Environment file "!YAML!" not found. Aborting...
  exit /b 1
)
echo %INFO% Using environment file "!YAML!".


:: --------------------------------------------------------
:: Determine cache directory
:: --------------------------------------------------------
if exist "%~d0\CACHE" (
  set "_CACHE=%~d0\CACHE"
  echo %INFO% Using "!_CACHE!" cache directory.
) else (
  if exist "%~dp0CACHE" (
    set "_CACHE=%~dp0CACHE"
    echo %INFO% Using "!_CACHE!" cache directory.
  ) else (
    set "_CACHE=%TEMP%"
    echo %INFO% Cache directory "!_CACHE!" does not exist. Will use TEMP instead.
  )
)


:: --------------------------------------------------------
:: Determine base components of environment path
:: --------------------------------------------------------
set "_ENV_PREFIX=%~dpn0"
if not exist "%_ENV_PREFIX%" md "%_ENV_PREFIX%"


:: --------------------------------------------------------
:: Point CONDA_PKGS_DIRS to package cache directory
:: --------------------------------------------------------
set CONDA_PKGS_DIRS=%_CACHE%\python\pkgs
if not defined CONDA_PKGS_DIRS (
  set CONDA_PKGS_DIRS=%_PKGS_DIR%
) else (
  set _PKGS_DIR=%CONDA_PKGS_DIRS%
)
if not exist "%CONDA_PKGS_DIRS%" md "%CONDA_PKGS_DIRS%"


:: --------------------------------------------------------
:: Download Micromamba
:: --------------------------------------------------------
call :MICROMAMBA_DOWNLOAD

:: --------------------------------------------------------
:: Create new Python environment, unless Python.exe already exist 
:: --------------------------------------------------------
if not exist "%_ENV_PREFIX%\python.exe" (
  call :CREATE_ENV
) else (
  echo %WARN% Found existing "%_ENV_PREFIX%\python.exe". Skip bootstrapping...
)

:: --------------------------------------------------------
:: Import extra env, if requested.
:: --------------------------------------------------------
call :EXTRA_ENV %*


exit /b 0
:: ============================================================================
:: ============================================================================
:: ============================================================================


:: ============================================================================ MICROMAMBA_DOWNLOAD BEGIN
:: ============================================================================
:MICROMAMBA_DOWNLOAD

:: --------------------------------------------------------
:: Download Micromamba
:: --------------------------------------------------------
set "RELEASE_URL=https://github.com/mamba-org/micromamba-releases/releases/latest/download/micromamba-win-64"
set "MAMBA_EXE=%_CACHE%\micromamba\micromamba.exe"
if not exist "%_CACHE%\micromamba" md "%_CACHE%\micromamba"
if exist "%MAMBA_EXE%" (
  echo %INFO% Using cached "%MAMBA_EXE%"
) else (
  echo %INFO% Downloading: %RELEASE_URL%
  echo %INFO% Destination: %MAMBA_EXE%
  curl --fail --retry 3 --retry-delay 2 -L -o "%MAMBA_EXE%" "%RELEASE_URL%"
  if not !ERRORLEVEL! equ 0 (
    echo %ERROR% Micromamba download failure. Aborting bootstrapping...
    exit /b 1
  )
)
set RELEASE_URL=

exit /b 0
:: ============================================================================
:: ============================================================================ MICROMAMBA_DOWNLOAD END


:: ============================================================================ CREATE_ENV BEGIN
:: ============================================================================
:CREATE_ENV

:: --------------------------------------------------------
:: Create new Python environment
:: --------------------------------------------------------
echo %INFO% Creating new Python environment...
if exist "%APPDATA%\mamba" (
  echo %WARN% Warning: I am about to delete "%APPDATA%\mamba". Press any key to continue.
  pause
  rmdir /Q /S "%APPDATA%\mamba"
)

:: -------------------------------------------
:: --- Preactivate development environment ---
:: -------------------------------------------
:: conda_far.bat is used to activate shell with MS Build Tools, Conda, and necessary libraries.
:: This script is a manager calling individual activation scripts. The "/batch" parameter is
:: necessary to skip launch of FAR MANAGER. CONDA_PREFIX is temporarily set, so that environment
:: variables associated with the Conda development environment to be created are forcefully set
:: or updated. For example, Conda package LibJPEG-Turbo installs the entire library, not just a
:: Python wrapper. This library is a build dependency for the "ffcv" package, which is available
:: only via "pip". pip dependencies specified in an environment file are installed after Conda
:: packages, so by the time LibJPEG-Turbo is actually need for compilation of FFCV, LibJPEG-Turbo
:: is already available. This way the entire environment is installed from the same environment
:: file, and the necessary MSVC variables not set by LibJPEG-Turbo, are available, as they are
:: set in advance.

if exist "%~dp0conda_far.bat" (
  echo %INFO% Preactivating dev environment.
  set "CONDA_PREFIX=%_ENV_PREFIX%"
  call "%~dp0conda_far.bat" /preactivate
  set "CONDA_PREFIX="
)

set PKGS=mamba conda uv %_PYTHON_PKG%
echo:
echo === call "%MAMBA_EXE%" create -vv --yes --no-rc --use-uv -f "%YAML%" --prefix "%_ENV_PREFIX%" %PKGS% ===
call "%MAMBA_EXE%" create -vv --yes --no-rc --use-uv -f "%YAML%" --prefix "%_ENV_PREFIX%" %PKGS%
if not !ERRORLEVEL! equ 0 (
  echo %ERROR% Failed to create a new environment. ERRORLEVEL: !ERRORLEVEL!. Aborting...
  exit /b !ERRORLEVEL!
) else (
  echo %OKOK% Environment "%_ENV_PREFIX%" is created.
)
echo:
set PKGS=


:: --------------------------------------------------------
:: Create activation script with FAR Manager
:: --------------------------------------------------------
(
  echo @echo off
  echo:
  echo call "%%~dp0mamba.bat" activate
  echo cmd /K """Far.bat"" ""%%CD%%\.."""
  echo:
) >"%_ENV_PREFIX%\condabin\conda_far.bat"

exit /b 0
:: ============================================================================
:: ============================================================================ CREATE_ENV END


:: ============================================================================ EXTRA_ENV BEGIN
:: ============================================================================
:EXTRA_ENV

setlocal
:: --------------------------------------------------------
:: Import additional environment
:: --------------------------------------------------------
echo:
echo %INFO% EXTRA ENVIRONMENTS

set "MAMBA_BAT=%_ENV_PREFIX%\condabin\mamba.bat"
if not exist "%MAMBA_BAT%" (
  echo %WARN% "%MAMBA_BAT%" not found... Skipping any extras.
  endlocal & exit /b 0

)
set "CONDA_BAT=%_ENV_PREFIX%\condabin\conda.bat"
if not exist "%CONDA_BAT%" (
  echo %WARN% "%CONDA_BAT%" not found... Skipping any extras.
  endlocal & exit /b 0

)

:: --------------------------------------------------------
:: Activate environment
:: --------------------------------------------------------
call "%MAMBA_BAT%" activate
call python.exe --version

:: --------------------------------------------------------
:: Command line environment
:: --------------------------------------------------------
echo:
echo %INFO% CHECKING COMMAND LINE EXTRA ENVIRONMENT

set "YAML_EXTRA=%~1"
if not defined YAML_EXTRA goto :SKIP_ARG_YAML
if /I not "%YAML_EXTRA:~-4%"==".yml" (
  echo %WARN% First argument is not *.yml: "%YAML_EXTRA%". Skipping...
  goto :SKIP_ARG_YAML
)
if not exist "%YAML_EXTRA%" (
  echo %WARN% "%YAML_EXTRA%" does not exist. Skipping...
  goto :SKIP_ARG_YAML
)

echo %INFO% importing environment file "%YAML_EXTRA%".
rem mamba hangs with Python 3.9 (not clear if the old Python version causes specific problems here)?
rem call "%MAMBA_BAT%" env update -vv --yes --no-rc --use-uv -f "%YAML%" --prefix "%_ENV_PREFIX%"

call "%CONDA_BAT%" env update -vv -f "%YAML_EXTRA%" --prefix "%_ENV_PREFIX%"

:SKIP_ARG_YAML
:: --------------------------------------------------------
:: Default extra environment
:: --------------------------------------------------------
echo:
echo %INFO% CHECKING DEFAULT EXTRA ENVIRONMENT

set "YAML_EXTRA=%YAML:~0,-4%_Extra_Default.yml"
if exist "%YAML_EXTRA%" (
  echo %INFO% Found default extra env file "%YAML_EXTRA%". Importing...
  call "%CONDA_BAT%" env update -vv -f "%YAML_EXTRA%" --prefix "%_ENV_PREFIX%"
)

endlocal & exit /b 0
:: ============================================================================
:: ============================================================================ EXTRA_ENV END
