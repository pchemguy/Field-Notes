@echo off


echo :========== ========== ========== ========== ==========:
echo  Bootstrapping Micromamba
echo :---------- ---------- ---------- ---------- ----------:

:: --- Escape sequence templates for color coded console output ---

call :COLOR_SCHEME

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
if not defined _CACHE (
  call :CACHE_DIR
  set "EXIT_STATUS=!ERRORLEVEL!"
) else (
  set "EXIT_STATUS=0"
)
if not "!EXIT_STATUS!"=="0" (
  echo %ERROR% Failed to set CACHE directory. Aborting...
  exit /b !EXIT_STATUS!
)
if not defined _CACHE (
  echo %ERROR% Failed to set CACHE directory. Aborting...
  exit /b 1
)
echo:

:: --------------------------------------------------------
:: Download Libraries
:: --------------------------------------------------------
call "%~dp0libs.bat"
set "EXIT_STATUS=!ERRORLEVEL!"
if not "%EXIT_STATUS%"=="0" (
  echo %ERROR% Failed to obtain libraries. ERRORLEVEL: %EXIT_STATUS%. Script: "%~dp0libs.bat" Aborting...
  exit /b %EXIT_STATUS%
)
call :COLOR_SCHEME

:: --------------------------------------------------------
:: Determine base components of environment path
:: --------------------------------------------------------
set "_ENV_PREFIX=%~dpn0"
if not exist "%_ENV_PREFIX%" md "%_ENV_PREFIX%"


:: --------------------------------------------------------
:: Point CONDA_PKGS_DIRS and PIP_CACHE_DIR to package cache directory
:: --------------------------------------------------------
set "CONDA_PKGS_DIRS=%_CACHE%\Python\pkgs"
if not defined CONDA_PKGS_DIRS (
  set "CONDA_PKGS_DIRS=%_PKGS_DIR%"
) else (
  set "_PKGS_DIR=%CONDA_PKGS_DIRS%"
)
if not exist "%CONDA_PKGS_DIRS%" md "%CONDA_PKGS_DIRS%"
set "PIP_CACHE_DIR=%~d0\CACHE\Python\pip"

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


:: ============================================================================ COLOR_SCHEME BEGIN
:: ============================================================================
:: --------------------------------------------------------
:: COLOR SCHEME
:: --------------------------------------------------------
:COLOR_SCHEME

:: --- Set console color scheme

set  "INFO=[100;92m [INFO]  [0m"
set  "OKOK=[103;94m -[OK]-  [0m"
set  "WARN=[106;35m [WARN]  [0m"
set "ERROR=[105;34m [ERROR] [0m"

exit /b 0
:: ============================================================================ 
:: ============================================================================ COLOR_SCHEME END


:: ============================================================================ CACHE_DIR BEGIN
:: ============================================================================
:CACHE_DIR
:: --------------------------------------------------------
:: Determine cache directory
:: --------------------------------------------------------
if exist "%_CACHE%" (
  goto :CACHE_DIR_SET
) else (
  set "_CACHE=%TEMP%"
)

if exist "%~d0\CACHE" (
  set "_CACHE=%~d0\CACHE"
  goto :CACHE_DIR_SET
)

if exist "%~dp0CACHE" (
  set "_CACHE=%~dp0CACHE"
  goto :CACHE_DIR_SET
)

if exist "%USERPROFILE%\Downloads" (
  if exist "%USERPROFILE%\Downloads\CACHE" (
    set "_CACHE=%USERPROFILE%\Downloads\CACHE"
  ) else (
    set "_CACHE=%USERPROFILE%\Downloads"
  )
  goto :CACHE_DIR_SET
)

:CACHE_DIR_SET
:: --------------------------------------------------------
:: Verify file system access
:: --------------------------------------------------------
set "_DUMMY=%_CACHE%\$$$_DELETEME_ACCESS_CHECK_$$$"
if exist "%_DUMMY%" rmdir /Q /S "%_DUMMY%"
set "EXIT_STATUS=!ERRORLEVEL!"
if exist "%_DUMMY%" set "EXIT_STATUS=1"
if not "!EXIT_STATUS!"=="0" (
  echo %ERROR% Failed to delete test directory "%_DUMMY%".
  echo %ERROR% Expected a full-access at this location "%_CACHE%".
  echo %ERROR% Aborting...
  exit /b !EXIT_STATUS!
)

md "%_DUMMY%"
set "EXIT_STATUS=!ERRORLEVEL!"
if not exist "%_DUMMY%" set "EXIT_STATUS=1"
if not "!EXIT_STATUS!"=="0" (
  echo %ERROR% Failed to create test directory "%_DUMMY%".
  echo %ERROR% Expected a full-access at this location "%_CACHE%".
  echo %ERROR% Aborting...
  exit /b !EXIT_STATUS!
)

echo %INFO% CACHE directory: "%_CACHE%".

exit /b 0
:: ============================================================================
:: ============================================================================ CACHE_DIR END


:: ============================================================================ MICROMAMBA_DOWNLOAD BEGIN
:: ============================================================================
:MICROMAMBA_DOWNLOAD

:: --------------------------------------------------------
:: Download Micromamba
:: --------------------------------------------------------
echo %WARN% Micromamba
set "RELEASE_URL=https://github.com/mamba-org/micromamba-releases/releases/latest/download/micromamba-win-64"
set "MAMBA_EXE=%_CACHE%\micromamba\micromamba.exe"
if not exist "%_CACHE%\micromamba" md "%_CACHE%\micromamba"
if exist "%MAMBA_EXE%" (
  echo %INFO% Micromamba: Using cached "%MAMBA_EXE%"
) else (
  echo %INFO% Micromamba: Downloading: %RELEASE_URL%
  echo %INFO% Micromamba: Destination: %MAMBA_EXE%
  curl --fail --retry 3 --retry-delay 2 -L -o "%MAMBA_EXE%" "%RELEASE_URL%"
  set "EXIT_STATUS=!ERRORLEVEL!"
  if not "!EXIT_STATUS!"=="0" (
    echo %ERROR% Micromamba: Download failure. Aborting bootstrapping...
    exit /b !EXIT_STATUS!
  )
)
set RELEASE_URL=
echo %OKOK% Micromamba: Completed
echo:

exit /b 0
:: ============================================================================
:: ============================================================================ MICROMAMBA_DOWNLOAD END


:: ============================================================================ CREATE_ENV BEGIN
:: ============================================================================
:CREATE_ENV

:: --------------------------------------------------------
:: Create new Python environment
:: --------------------------------------------------------
echo %WARN% Creating new Python environment...
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
  set "_CONDA_PREFIX=%_ENV_PREFIX%"
  call "%~dp0conda_far.bat" /preactivate
  set "_CONDA_PREFIX="
)

set PKGS=mamba conda uv %_PYTHON_PKG%
echo:
echo === call "%MAMBA_EXE%" create -vv --yes --no-rc --use-uv -f "%YAML%" --prefix "%_ENV_PREFIX%" %PKGS% ===
call "%MAMBA_EXE%" create -vv --yes --no-rc --use-uv -f "%YAML%" --prefix "%_ENV_PREFIX%" %PKGS%
set "EXIT_STATUS=%ERRORLEVEL%"
if not "%EXIT_STATUS%"=="0" (
  echo %ERROR% Failed to create a new environment. ERRORLEVEL: %EXIT_STATUS%. Aborting...
  exit /b %EXIT_STATUS%
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
