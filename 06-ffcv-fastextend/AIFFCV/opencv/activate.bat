@echo off

set  "INFO=[100;92m [INFO]  [0m"
set  "OKOK=[103;94m -[OK]-  [0m"
set  "WARN=[106;35m [WARN]  [0m"
set "ERROR=[105;34m [ERROR] [0m"


if /I "%~1"=="/f" (set "_FORCE=1") else (set "_FORCE=")


:: This script is designed to update environment variables to be used by
:: MS Build Tools toolchain when a PyPI package being installed (`pip install`)
:: must be buit/compiled and has build dependency on this library. This script
:: should resolve potential missing linker dependencies in case the setup.py 
:: script included in the package is disfunctional. For packages with proper
:: setup.py logic this script should effectively be a NOOP.
:: 
:: The primary focus is on updating the following environment variables:
:: - INCLUDE: directories with relevant *.h header files.
:: - LIB:     directories with relevant *.lib import library files.
:: - LINK:    specific names of *.lib import library files to be used; while
::            there are dedicated variables for passing location of *.h (compiler)
::            and *.lib (linker) files to the build toolchain, MS linker does not
::            support a similar variable for specifying names of *.lib files.
::            To pass these names to the build process initiated by pip/setuptools,
::            a general LINK variable provided by MS linker is used instead.
:: - Path:    DLL location, necessary for package use, not building.
:: 
:: The script is structured into three section focused on updating compiler
:: (INCLUDE), linker (LIB and LINK), and runtime (Path) variables. Each section
:: begins with config part conatining the following variables to be set:
:: - runtime: 
::   - _BINPATH - location of DLL files.
::   - _BINNAME - space-separated string with names of required key DLLs.
:: - compiler:
::   - _INCPATH - location of header files (usually the "include" directory,
::                even if contains subdirectories.
::   - _INCNAME - space-separated string with names of required key *.h files.
::   - _INCEXT  - subdirectory within the top "include" directory, pointing to
::                location of the key files. Thera large projects that structure
::                include directory, but include relative path within the project's
::                main "include" directory as part of the "#include" directive.
::                In such a case, only the path to the "include" directory needs
::                to be passed to the compiler. This variable is therefore used
::                solely within this script to enable exsitence check on specified
::                key header files.
:: - linker:
::   - _LIBPATH - location of import library files.
::   - _LIBNAME - space-separated string with names of ALL required *.lib files
::                to be passed to the linker.
:: 
:: Verification checks and limitations.
:: For each of the three varible sets, this script verifies that the combination
:: of the two xxxPATH/xxxNAME variables within each set points to existing files.
:: (Note, the script uses solely "if exist" construct for the purpose of this check
:: and does not verify that validated file system paths point to files rather than
:: directories. While such additional check could be performed, it would necessitate
:: complicating script logic with additional processing of the filterd `dir` command.
:: Such a "false positive" is considered sufficiently unlikely that this extra check
:: is not actually implemented. The current logic also assumes that each xxxPATH
:: variable contains a single absolute path to be checked and added to the
:: corresponding variable. While some project may in principle necessitate addition
:: of more than one location per category, such a requirement is considered sufficently
:: rare that the associated more complex processing with nested loops is not implemented.
:: 
:: The script is set to verify Path/INCLUDE/LIB/LINK items by checking existence
:: of specified key *.dll, *.h, and *.lib files. If this check fails, by default,
:: respective items will not be updated. However, this script may also be used
:: to preactivate environment, so that subsequent environment bootstrapping
:: process could import an environment file containing pip packages with build
:: dependencies among Conda packages from the same file. Because Conda packages
:: are installed first by Conda/Mamba/Micromamba, such dependencies will be
:: available by the time the specified pip packages are ready to be installed.
:: Use "/f" switch to force environment initialization, ignoring check results.

set "_LIBRARY=OpenCV"
echo:
echo ==========================================================================
echo %INFO% Setting up --- %_LIBRARY% ---
echo %INFO%
echo %INFO% "%~0"
echo ==========================================================================
echo:


echo ==========================================================================
echo %INFO% %_LIBRARY%: PATH
echo ==========================================================================
set "_BINPATH=%~dp0build\x64\vc15\bin"
set "_BINNAME=opencv_videoio_ffmpeg460_64.dll"

set "EXIT_STATUS=0"
for %%I in (%_BINNAME%) do (
  set "_MOD=%_BINPATH%\%%I"
  if exist "!_MOD!" (
    echo %INFO% %_LIBRARY%:   Library "!_MOD!" found.
  ) else (
    echo %ERROR% %_LIBRARY%:   Library "!_MOD!" NOT found!
    set /a "EXIT_STATUS=!EXIT_STATUS!+1"
  )
)  
if defined _FORCE (set "EXIT_STATUS=0")
if %EXIT_STATUS% equ 0 (
  echo %INFO% %_LIBRARY%:   "Path=%%Path%%;%_BINPATH%"
  set "Path=%Path%;%_BINPATH%"
) else (
  echo %ERROR% %_LIBRARY%:   PATH NOT UPDATED
)
set "_MOD="
set "EXIT_STATUS="

set "_BINPATH="
set "_BINNAME="


echo ==========================================================================
echo %INFO% %_LIBRARY%: INCLUDE
echo ==========================================================================
set "_INCPATH=%~dp0build\include"
set "_INCNAME=opencv.hpp"
set "_INCEXT=\opencv2"

set "EXIT_STATUS=0"
for %%I in (%_INCNAME%) do (
  set "_MOD=%_INCPATH%%_INCEXT%\%%I"
  if exist "!_MOD!" (
    echo %INFO% %_LIBRARY%:   Include "!_MOD!" found.
  ) else (
    echo %ERROR% %_LIBRARY%:   Include "!_MOD!" NOT found!
    set /a "EXIT_STATUS=!EXIT_STATUS!+1"
  )
)  
if defined _FORCE (set "EXIT_STATUS=0")
if %EXIT_STATUS% equ 0 (
  echo %INFO% %_LIBRARY%:   "INCLUDE=%_INCPATH%;%%INCLUDE%%"
  set "INCLUDE=%_INCPATH%;%INCLUDE%"
) else (
  echo %ERROR% %_LIBRARY%:   INCLUDE NOT UPDATED
)
set "_MOD="
set "EXIT_STATUS="

set "_INCPATH="
set "_INCNAME="


echo ==========================================================================
echo %INFO% %_LIBRARY%: LIB
echo ==========================================================================
set "_LIBPATH=%~dp0build\x64\vc15\lib"
set "_LIBNAME=opencv_world460.lib"

set "EXIT_STATUS=0"
for %%I in (%_LIBNAME%) do (
  set "_MOD=%_LIBPATH%\%%I"
  if exist "!_MOD!" (
    echo %INFO% %_LIBRARY%:   Lib "!_MOD!" found.
  ) else (
    echo %ERROR% %_LIBRARY%:   Lib "!_MOD!" NOT found!
    set /a "EXIT_STATUS=!EXIT_STATUS!+1"
  )
)  
if defined _FORCE (set "EXIT_STATUS=0")
if %EXIT_STATUS% equ 0 (
  echo %INFO% %_LIBRARY%:   "LIB=%_LIBPATH%;%%LIB%%"
  echo %INFO% %_LIBRARY%:   "_LIBLIB=%_LIBNAME% %%_LIBLIB%%"
  set "LIB=%_LIBPATH%;%LIB%"
  set "_LIBLIB=%_LIBNAME% %_LIBLIB%"
) else (
  echo %ERROR% %_LIBRARY%:   INCLUDE NOT UPDATED
)
set "_MOD="
set "EXIT_STATUS="

set "_LIBPATH="
set "_LIBNAME="


set  "INFO="
set  "OKOK="
set  "WARN="
set "ERROR="
set "_FORCE="
set "_LIBRARY="
