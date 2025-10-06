@echo off


REM Bootstrapping Python environment using Micromamba
REM   https://github.com/mamba-org/micromamba-releases
REM   https://github.com/mamba-org/mamba
REM   https://mamba.readthedocs.io/en/latest/installation/micromamba-installation.html
REM
REM Key Variables:
REM   MAMBA_ROOT_PREFIX
REM   MAMBA_BAT
REM   MAMBA_EXE


if not "%PYTHON_ENVS%"=="" (
    echo Envirnoment variable %%PYTHON_ENVS%% is set.
    echo Run this script from a clean environment. Exiting...
    exit /b 1
)


echo :========== ========== ========== ========== ==========:
echo  Bootstrapping Micromamba
echo :---------- ---------- ---------- ---------- ----------:


set _PY_V=
if defined _PY_V (
  echo:
  echo [+] Python version requested: "%_PY_V%".
  echo:
) else (
  echo:
  echo [+] Installing the latest Python version.
  echo:
)


if exist "%~d0\CACHE" (
  echo :========== ========== ========== ========== ==========:
  echo  Using "%~d0\CACHE" cache dirctory.
  echo :---------- ---------- ---------- ---------- ----------:
  set _CACHE=%~d0\CACHE
) else (
  echo :========== ========== ========== ========== ==========:
  echo  Cache dirctory "%~d0\CACHE" does not exist. Will use TEMP instead.
  echo :---------- ---------- ---------- ---------- ----------:
  set _CACHE=%TEMP%
)

set _PKGS_DIR=%_CACHE%\Python\pkgs

set _ENVS=%~d0\dev\Anaconda\envs
if not exist "%_ENVS%" (
  set _ENVS=%CD%
)
if not "%~1"=="" (
  set _ENV_NAME=%~1
) else (
  set _ENV_NAME=py
)

set _PYTHON_PKG=python
if defined _PY_V (
    set _ENV_NAME=%_ENV_NAME%_%_PY_V:.=_%
    set _PYTHON_PKG=%_PYTHON_PKG%=%_PY_V%
)
set _PY_V=


if exist "%_ENVS%\%_ENV_NAME%\python.exe" (
  echo:
  echo [+] Found existing "%_ENVS%\%_ENV_NAME%\python.exe". Aborting bootstrapping...
  echo:
  exit /b 1
)

if exist "%_ENVS%\%_ENV_NAME%" (
  echo:
  echo [+] Deleting existing prefix directory.
  echo:
  rmdir /S /Q "%_ENVS%\%_ENV_NAME%"
)


set _RELEASE_URL=https://github.com/mamba-org/micromamba-releases/releases/latest/download/micromamba-win-64
set MAMBA_EXE=%_PKGS_DIR%\micromamba.exe
if exist "%MAMBA_EXE%" (
  echo :========== ========== ========== ========== ==========:
  echo  Using cached "%MAMBA_EXE%"
  echo :---------- ---------- ---------- ---------- ----------:
) else (
  echo :========== ========== ========== ========== ==========:
  echo  Downloading: %_RELEASE_URL%
  echo  Destination: %MAMBA_EXE%
  echo :---------- ---------- ---------- ---------- ----------:
  curl -L -o "%MAMBA_EXE%" "%_RELEASE_URL%"
)
set _RELEASE_URL=


echo:
echo [+] Creating new Python environment...
echo:
"%MAMBA_EXE%" create --prefix "%_ENVS%\%_ENV_NAME%" --yes

set MAMBA_ROOT_PREFIX=%_ENVS%\%_ENV_NAME%
set _MRP=%MAMBA_ROOT_PREFIX%
set _ENVS=
set _ENV_NAME=


echo --- Set junction to package cache
if exist "%_PKGS_DIR%" (
  if exist "%_MRP%\pkgs" rmdir /S /Q "%_MRP%\pkgs"
  mklink /j "%_MRP%\pkgs" "%_PKGS_DIR%"
)
set _PKGS_DIR=

if not exist "%_MRP%\Scripts" mkdir "%_MRP%\Scripts"
copy /Y "%MAMBA_EXE%" "%_MRP%\Scripts"
set MAMBA_EXE=%_MRP%\Scripts\micromamba.exe

echo:
echo [+] Create shell scripts inside the target environment
echo:
"%MAMBA_EXE%" shell hook --shell cmd.exe -r "%_MRP%"
set CONDA_BIN=%_MRP%\condabin
set SCRIPTS=%_MRP%\Scripts
set MAMBA_BAT=%CONDA_BIN%\micromamba.bat
set PATH=%CONDA_BIN%;%PATH%


echo:
echo [+] Obtain sed to patch absolute hardcoded paths.
echo:
where sed.exe 2>nul
if %ErrorLeveL% equ 0 (
  set SED=sed.exe
) else (
  call "%~dp0get_sed.bat" "%_CACHE%"
  set SED=%_CACHE%\sed\sed.exe
)


echo:
echo [+] Patch absolute paths in mamba scripts
echo:
set _TARGET=%MAMBA_BAT%
set _DEL_MAMBA_EXE=/@SET \"MAMBA_EXE=.*\"/d

set _PATCH_ENV_VAR=s#@SET .MAMBA_ROOT_PREFIX=.*#^
  set CUR_DIR=%%CD%%\n^
  cd /d \"%%~dp0..\"\n^
  set MAMBA_ROOT_PREFIX=%%CD%%\n^
  cd /d \"%%CUR_DIR%%\"\n^
  set CUR_DIR=\n^
  set MAMBA_EXE=%%MAMBA_ROOT_PREFIX%%\\Scripts\\micromamba.exe#

"%SED%" -i.bak "%_DEL_MAMBA_EXE%; %_PATCH_ENV_VAR%" "%_TARGET%"

set _DEL_MAMBA_EXE=
set _PATCH_ENV_VAR=
set _TARGET=
set SED=


echo:
echo [+] Activating Python environment - Micromamba.
echo     MUST use micromamba.bat wrapper, not micromamba.exe directly.
echo:
call "%MAMBA_BAT%" activate


move /Y "%SCRIPTS%\activate.bat" "%SCRIPTS%\activate.bat.micro"
move /Y "%CONDA_BIN%\activate.bat" "%CONDA_BIN%\activate.bat.micro"
move /Y "%CONDA_BIN%\mamba_hook.bat" "%CONDA_BIN%\mamba_hook.bat.micro"


set PKGS=mamba uv %_PYTHON_PKG%
call "%MAMBA_BAT%" install --yes --override-channels -c conda-forge --prefix "%_MRP%" %PKGS%
set _PYTHON_PKG=
set PKGS=

set MAMBA_EXE=%_MRP%\Library\bin\mamba.exe
set MAMBA_BAT=%CONDA_BIN%\mamba.bat

echo:
echo [+] Activating Python environment - Mamba.
echo     MUST use mamba.bat wrapper, not mamba.exe directly.
echo:
call "%MAMBA_BAT%" activate

set PKGS=conda
call "%MAMBA_BAT%" install --yes --override-channels -c conda-forge --prefix "%_MRP%" %PKGS%


cd /d "%~dp0..\.."
if exist "%CD%\__shortcut__" if not exist "%_MRP%\__shortcut__" (
    md "%_MRP%\__shortcut__"
    xcopy /H /Y /B /E /Q "%CD%\__shortcut__" "%_MRP%\__shortcut__"
)
if exist "%CD%\__home__" if not exist "%_MRP%\__home__" (
    md "%_MRP%\__home__"
    xcopy /H /Y /B /E /Q "%CD%\__home__" "%_MRP%\__home__"
)
if exist "%CD%\__AppData__" if not exist "%_MRP%\__AppData__" (
    md "%_MRP%\__AppData__"
    xcopy /H /Y /B /E /Q "%CD%\__AppData__" "%_MRP%\__AppData__"
)
