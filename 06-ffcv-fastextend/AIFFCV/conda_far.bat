@echo off


:: --- Use `/batch` to activate shell environment without starting FAR MANAGER ---
:: --- Use `/preactivate` to preactivate environment ---

call :COLOR_SCHEME

if /I "%~1"=="/preactivate" (
  set "_MODE=/f"
) else (
  set "_MODE="
)


set "_VSINSTALLDIR=%~dp0..\MSBuildTools"
set "_VCVARS=%_VSINSTALLDIR%\VC\Auxiliary\Build\vcvars64.bat"

if not defined VSINSTALLDIR (
  if exist "%_VCVARS%" (
    echo:
    echo %WARN% Activating MS Build Tools.
    call "%_VCVARS%"
  )
)
if not exist "%VSINSTALLDIR%\VC\Auxiliary\Build\vcvars64.bat" (
  echo %ERROR% MS Build Tools activation script not found: "%_VCVARS%".
)
set "_VCVARS="
set "_VSINSTALLDIR="

if exist "%CONDA_PREFIX%\condabin\conda.bat" (
  echo:
  echo %WARN% Activating Conda.
  call "%CONDA_PREFIX%\condabin\conda.bat" activate
) else (
  echo %ERROR% Conda activation script not found: "%CONDA_PREFIX%\condabin\conda.bat".
)

if exist "%~dp0pthreads\activate.bat" (
  echo:
  echo %WARN% Activating pthreads library.
  call "%~dp0pthreads\activate.bat" %_MODE%
  call :COLOR_SCHEME
) else (
  echo %ERROR% pthreads activation script not found: "%~dp0pthreads\activate.bat".
)

if exist "%~dp0opencv\activate.bat" (
  echo:
  echo %WARN% Activating OpenCV library.
  call  "%~dp0opencv\activate.bat" %_MODE%
  call :COLOR_SCHEME
) else (
  echo %WARN% OpenCV activation script not found: "%~dp0opencv\activate.bat".
)

if exist "%~dp0libjpeg-turbo\activate.bat" (
  echo:
  echo %WARN% Activating LibJPEG-Turbo library.
  call "%~dp0libjpeg-turbo\activate.bat" %_MODE%
  call :COLOR_SCHEME
) else (
  echo %ERROR% LibJPEG-Turbo activation script not found: "%~dp0libjpeg-turbo\activate.bat".
)
echo ==========================================================================
echo:

set "_MODE="
set "_PREFIX="
set "_VCVARS="

:: --- Update INCLUDE if new item has not been added before ---

set "_INCPATH=%CONDA_PREFIX%\Library\include"
if "!INCLUDE!"=="!INCLUDE:%_INCPATH%=!" (
  set "INCLUDE=%_INCPATH%;%INCLUDE%"
) else (
  echo [INFO] "%_INCPATH%" already added to %%INCLUDE%%
)
set "_INCPATH="

:: --- Update LIB if new item has not been added before ---

set "_LIBPATH=%CONDA_PREFIX%\Library\lib"
if "!LIB!"=="!LIB:%_LIBPATH%=!" (
  set "LIB=%_LIBPATH%;%LIB%"
) else (
  echo [INFO] "%_LIBPATH%" already added to %%LIB%%
)
set "_LIBPATH="

:: --- Update LINK if new item has not been added before ---

if not defined LINK set "LINK= "
if "!LINK!"=="!LINK:%_LIBLIB%=!" (
  set "LINK=%_LIBLIB% %LINK%"
) else (
  echo [INFO] "%_LIBLIB%" already added to %%LINK%%
)
set "_LIBLIB="

:: --- Set pip cache location ---

set "PIP_CACHE_DIR=%~d0\CACHE\Python\pip"

:: --- Have Python/setuptools/distutils use preactivated MS Build Tools environment. ---

set "DISTUTILS_USE_SDK=1"

set  "INFO="
set  "OKOK="
set  "WARN="
set "ERROR="

:: --- Use "/batch" to activate shell environment without starting FAR MANAGER ---

if /I "%~1"=="/batch" (goto :EXIT_MAIN)
if /I "%~1"=="/preactivate" (goto :EXIT_MAIN)

cmd /K """Far.bat"" ""%~dp0Anaconda"""
rem set "LINK=turbojpeg.lib opencv_world460.lib"


:EXIT_MAIN
set  "INFO="
set  "OKOK="
set  "WARN="
set "ERROR="

exit /b 0


:COLOR_SCHEME
:: --- Set console color scheme

set  "INFO=[100;92m [INFO]  [0m"
set  "OKOK=[103;94m -[OK]-  [0m"
set  "WARN=[106;35m [WARN]  [0m"
set "ERROR=[105;34m [ERROR] [0m"

exit /b 0
