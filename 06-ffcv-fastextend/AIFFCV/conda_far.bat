@echo off


:: --- Use `/batch` to activate shell environment without starting FAR MANAGER ---
:: --- Use `/preactivate` to preactivate environment ---

if /I "%~1"=="/preactivate" (
  set "_MODE=/f"
) else (
  set "_MODE="
)
set "EXIT_STATUS="


:: --- Escape sequence templates for color coded console output ---

call :COLOR_SCHEME

:: --- Make sure cmd.exe delayed expansion is enabled by default ---

call :CHECK_DELAYED_EXPANSION
if not "%ERRORLEVEL%"=="0" (
  set "EXIT_STATUS=1"
  goto :EXIT_MAIN
)

:: --- Base / Root environment guard ---

call :NO_ROOT_ENVIRONMENT

:: --- MS Build Tools ---
::
:: Assume that activated shell must have variable VSINSTALLDIR set and
:: main activation script present in
:: "%VSINSTALLDIR%\VC\Auxiliary\Build\vcvarsall.bat"

if exist "%VSINSTALLDIR%\VC\Auxiliary\Build\vcvarsall.bat" goto :SKIP_MSBUILD_ACTIVATION

set "_VSINSTALLDIR=%~dp0..\MSBuildTools"
set "_VCVARS=%_VSINSTALLDIR%\VC\Auxiliary\Build\vcvars64.bat"
if not exist "%_VCVARS%" (
  set "_VSINSTALLDIR=%~d0\dev\MSBuildTools"
  set "_VCVARS=!_VSINSTALLDIR!\VC\Auxiliary\Build\vcvars64.bat"
)

if exist "%_VCVARS%" (
  echo:
  echo %WARN% Activating MS Build Tools.
  call "%_VCVARS%"
  set "EXIT_STATUS=!ERRORLEVEL!"
  if not "!EXIT_STATUS!"=="0" (
    echo %ERROR% MS Build Tools activation failed!
  ) else (
    echo %OKOK% MS Build Tools activation succeeded!
  )
)

if not exist "%VSINSTALLDIR%\VC\Auxiliary\Build\vcvarsall.bat" (
  echo %ERROR% MS Build Tools activation script not found: "%VSINSTALLDIR%\VC\Auxiliary\Build\vcvarsall.bat".
  echo %ERROR% Tried:                                      "%_VCVARS%".
  echo %INFO% If MS Build Tools are installed, either
  echo %INFO%   - verify or ajust variables above AND/OR
  echo %INFO%   - start this script from a preactivated MS Build Tools shell
  echo %INFO% See this accepted SO answer https://stackoverflow.com/a/64262038/17472988
  echo %INFO% regarding MS Build Tools installation.
  echo:
  echo %INFO% FFCV will not get installed without compiler.
  pause
)
set "_VCVARS="
set "_VSINSTALLDIR="

:SKIP_MSBUILD_ACTIVATION

:: --- Default Conda Prefix ---

if defined __CONDA_PREFIX (
  set "__CONDA_PREFIX=_CONDA_PREFIX"
) else (
  set "__CONDA_PREFIX=%~dp0Anaconda"
)

:: --- Unless preactivating, python.exe and conda.bat must exist in Conda environment ---

if /I not "%_MODE%"=="/f" (
  if not exist "%__CONDA_PREFIX%\python.exe" (
    echo:
    echo %ERROR% Python not found: "%__CONDA_PREFIX%\python.exe"! Aborting...
    exit /b 1
  )
  if not exist "%__CONDA_PREFIX%\condabin\conda.bat" (
    echo:
    echo %ERROR% Conda activation script not found: "%__CONDA_PREFIX%\condabin\conda.bat". Aborting...
    exit /b 1
  ) else (
    echo:
    echo %WARN% Activating Conda.
    call "%__CONDA_PREFIX%\condabin\conda.bat" activate
    set "EXIT_STATUS=!ERRORLEVEL!"
  )
  if not "!EXIT_STATUS!"=="0" (
    echo %ERROR% Conda activation failed! Aborting...
    exit /b !EXIT_STATUS!
  ) else (
    echo %OKOK% Conda activation succeeded!
  )
)

:: --- pthreads ---

if exist "%~dp0pthreads\activate.bat" (
  echo:
  echo %WARN% Activating pthreads library.
  call "%~dp0pthreads\activate.bat" %_MODE%
  set "EXIT_STATUS=!ERRORLEVEL!"
  call :COLOR_SCHEME
) else (
  echo %ERROR% pthreads activation script not found: "%~dp0pthreads\activate.bat".
)
if not "%EXIT_STATUS%"=="0" (
  echo %ERROR% pthreads activation failed!
) else (
  echo %OKOK% pthreads activation succeeded!
)

:: --- OpenCV ---

if exist "%~dp0opencv\activate.bat" (
  echo:
  echo %WARN% Activating OpenCV library.
  call  "%~dp0opencv\activate.bat" %_MODE%
  set "EXIT_STATUS=!ERRORLEVEL!"
  call :COLOR_SCHEME
) else (
  echo %WARN% OpenCV activation script not found: "%~dp0opencv\activate.bat".
)
if not "%EXIT_STATUS%"=="0" (
  echo %ERROR% OpenCV activation failed!
) else (
  echo %OKOK% OpenCV activation succeeded!
)

:: --- LibJPEG-Turbo ---

if exist "%~dp0libjpeg-turbo\activate.bat" (
  echo:
  echo %WARN% Activating LibJPEG-Turbo library.
  call "%~dp0libjpeg-turbo\activate.bat" %_MODE%
  set "EXIT_STATUS=!ERRORLEVEL!"
  call :COLOR_SCHEME
) else (
  echo %ERROR% LibJPEG-Turbo activation script not found: "%~dp0libjpeg-turbo\activate.bat".
)
if not "%EXIT_STATUS%"=="0" (
  echo %ERROR% LibJPEG-Turbo activation failed!
) else (
  echo %OKOK% LibJPEG-Turbo activation succeeded!
)
echo ==========================================================================
echo:

set "_MODE="
set "_PREFIX="
set "_VCVARS="

:: --- Reset COLOR_SCHEME as it may have been reset n called scripts. ---

call :COLOR_SCHEME

:: --- Update INCLUDE if new item has not been added before ---

set "_INCPATH=%__CONDA_PREFIX%\Library\include"
if "!INCLUDE!"=="!INCLUDE:%_INCPATH%=!" (
  set "INCLUDE=%_INCPATH%;%INCLUDE%"
) else (
  echo %INFO% "%_INCPATH%" already added to %%INCLUDE%%
)
set "_INCPATH="

:: --- Update LIB if new item has not been added before ---

set "_LIBPATH=%__CONDA_PREFIX%\Library\lib"
if "!LIB!"=="!LIB:%_LIBPATH%=!" (
  set "LIB=%_LIBPATH%;%LIB%"
) else (
  echo %INFO% "%_LIBPATH%" already added to %%LIB%%
)
set "_LIBPATH="

:: --- Update LINK if new item has not been added before ---

if not defined LINK set "LINK= "
if "!LINK!"=="!LINK:%_LIBLIB%=!" (
  set "LINK=%_LIBLIB% %LINK%"
) else (
  echo %INFO% "%_LIBLIB%" already added to %%LINK%%
)
set "_LIBLIB="

:: --- Set pip cache location ---

set "PIP_CACHE_DIR=%~d0\CACHE\Python\pip"

:: --- Have Python/setuptools/distutils use preactivated MS Build Tools environment. ---

set "DISTUTILS_USE_SDK=1"

:: --- Clean up ---

set  "INFO="
set  "OKOK="
set  "WARN="
set "ERROR="

:: --- Use "/batch" to activate shell environment without starting FAR MANAGER ---

if /I "%~1"=="/batch" (goto :EXIT_MAIN)
if /I "%~1"=="/preactivate" (goto :EXIT_MAIN)

:: --- Start FAR MANAGER ---

set "_FARMANAGER="
for %%A in ("far.bat" "far.exe") do (
  where %%~A >nul 2>nul && (
    set "_FARMANAGER=%%~A"
    goto :START_FARMANAGER
  )
)

:START_FARMANAGER
if not defined _FARMANAGER (set "_FARMANAGER=cd")
set "_FARMANAGER=""%_FARMANAGER%"""
if defined _FARMANAGER cmd /K "%_FARMANAGER% ""%__CONDA_PREFIX%"""


:EXIT_MAIN

:: --- Clean up ---

set  "INFO="
set  "OKOK="
set  "WARN="
set "ERROR="
set "__CONDA_PREFIX="

exit /b %EXIT_STATUS%
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


:: ============================================================================ CHECK_DELAYED_EXPANSION BEGIN
:: ============================================================================
:CHECK_DELAYED_EXPANSION

echo:
echo %WARN% Checking cmd.exe delayed expansion availability


if "%ComSpec%"=="!ComSpec!" (
  echo %INFO% --------------------------
  echo %OKOK% CHECK PASSED
  echo %INFO% Delayed Expansion enabled!
  echo %INFO% --------------------------
  echo:
  exit /b 0
)


echo:
echo %INFO% ----------------------------------------------------------
echo %ERROR% CHECK FAILED
echo %INFO% cmd.exe Delayed Expansion is not active. Set the following
echo %INFO% setting (either variant should do), start a new shell, run
echo %INFO% this script again, and make sure the check passes.
echo %INFO% Otherwise, try rebooting your computer.
echo %INFO% ----------------------------------------------------------
echo: 
echo %INFO% Delayed expansion activation settings. 
echo: 
echo %INFO% ---------------------------------------------------------
echo %INFO% [HKEY_CURRENT_USER\Software\Microsoft\Command Processor]
echo %INFO% "DelayedExpansion"=dword:00000001
echo %INFO% "EnableExtensions"=dword:00000001
echo:%INFO% 
echo %INFO% --- OR ---
echo:
echo %INFO% [HKEY_LOCAL_MACHINE\Software\Microsoft\Command Processor]
echo %INFO% "DelayedExpansion"=dword:00000001
echo %INFO% "EnableExtensions"=dword:00000001
echo %INFO% ---------------------------------------------------------
echo:

exit /b 1
:: ============================================================================ 
:: ============================================================================ CHECK_DELAYED_EXPANSION END


:: ============================================================================ NO_ROOT_ENVIRONMENT BEGIN
:: ============================================================================
:: --------------------------------------------------------
:: NO_ROOT_ENVIRONMENT
::
:: This script should not be executed from a shell with active Python / Conda 
:: environment (visible conda.bat or python.exe). If found, issue a warning and
:: attempt to deactivate. Note, if active Python envirnoment was activated via
:: `conda activate` is should be possible to deactivate it via `conda deactivate`
:: If Python was placed on Path via Conda activation, deactivation should
:: remove it from Path. However, if Python is placed on Path independently,
:: for example via system-wide installation, deactivation will likely fail to
:: remove Python from Path. ALSO, if custom activation wrapper was used, such
:: as this very script, deactivation will not remove any custom envirnoment
:: settings. In such a case, effectively partial deactivation may result in
:: issues, potentially subtle, in the new environment. In particular, this
:: script activates external build dependencies for FFCV, and associted
:: settings may result in wrong dependency references and failed builds, if
:: new environment is not started from a clean system shell.
:: --------------------------------------------------------
:NO_ROOT_ENVIRONMENT

:: Check if Conda or Python is in Path

set "_CONDA="
set "_PYTHONE="
where "conda.bat" >nul 2>nul && (set "_CONDA=conda.bat")
where "python.exe" >nul 2>nul && (set "_PYTHON=python.exe")
if not defined _CONDA if not defined _PYTHONE exit /b 0

echo:
if defined _CONDA (
  echo %WARN% Detected "conda.bat" in Path!
)
if defined _PYTHONE (
  echo %WARN% Detected "python.exe" in Path!
)
echo %WARN% It is strongly recommended to start this script from a clean
echo %WARN% environment. No Conda or Python variables should be in Path.
echo %WARN% If you wish to proceed, the script will attempt to clean up
echo %WARN% environment (no guarantees)...
pause

if defined _CONDA (
  "%_CONDA %" deactivate
  set "CONDA_EXE="
  set "CONDA_PYTHON_EXE="
  set "CONDA_SHLVL="
)

exit /b 0
:: ============================================================================ 
:: ============================================================================ NO_ROOT_ENVIRONMENT END
