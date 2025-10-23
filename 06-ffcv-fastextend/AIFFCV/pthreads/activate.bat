@echo off

:: =====================================================================
::  Purpose:
::    Configures the MSVC toolchain environment for the PHTREADS-WIN32
::    dependency during a package build (e.g., pip install).
::
::    Intended to be *CALLED* by a parent script to
::    modify the caller's environment, not executed directly.
::
::  Arguments (Optional):
::    -   :     The default workflow with No arguments is to activate
::              environment only if all files are present. This workflow
::              is relevant for normal use of Python environment after 
::              installation is complete. However, is the binaries are
::              copied to CONDA_PREFIX (/i) and the dev files are not meant
::              to be used after installation is complete, this workflow
::              becomes unnecessary (the only runtime requirements of having
::              the DLL containing directory on the PATH is satisfied by
::              Conda environment activation process.
::    - /f:     Force. Sets the environment variables even if
::              target files (.dll, .lib, .h) are not found.
::              Useful for pre-configuring an environment.
::    - /i:     Install. Copies the library's .dll file(s) from
::              their source location to the Conda environment's
::              '%CONDA_PREFIX%\Library\bin' directory.
::              This supersedes the main environment setup logic.
::              This process is a NOOP, if using a conda package.
::              Note: This step is essential for runtime due to
::                    Python DLL loading implementation logic.
::
::  Preconditions:
::    - The CALLER's environment must have delayed expansion enabled
::      *prior* to calling this script. (This script cannot use 'setlocal'
::      as it would prevent modification of the caller's environment).
::    - CONDA_PREFIX or _CONDA_PREFIX must be set.
::    - NOCOLOR: If set, gracefully falls back to no color.
::
::  Postconditions (on success, without /i):
::    - Updates the CALLER's environment:
::      - set "Path=%_BINPATH%;%Path%"
::      - set "INCLUDE=%_INCPATH%;%INCLUDE%"
::      - set "LIB=%_LIBPATH%;%LIB%"
::      - set "LINK=%_LIBNAME% %LINK%"
:: =====================================================================

:: --- Escape sequence templates for color coded console output ---

call :COLOR_SCHEME

:: --- Settings for a Conda packge ---

set "__CONDA_PREFIX="
if defined CONDA_PREFIX (
  set "__CONDA_PREFIX=%CONDA_PREFIX%"
) else (if defined _CONDA_PREFIX (
  set "__CONDA_PREFIX=%_CONDA_PREFIX%"
))
if not defined __CONDA_PREFIX (
  echo %ERROR% %_LIBRARY%: Failed to determine target location.
  echo %ERROR% %_LIBRARY%: One of CONDA_PREFIX or _CONDA_PREFIX must be defined. Aborting...
  exit /b 1
)

:: --- Settings for a standalone copy ---
:: --------------------------------------
:: Note: If using an independent copy of the library, use this code instead.
set "PTH_PREFIX=%~dp0"
if "%PTH_PREFIX:~-1%/"=="\/" set "PTH_PREFIX=%PTH_PREFIX:~0,-1%"

:: --- CONFIG ---

set "_LIBRARY=PTHREADS"
set "_BINPATH=%PTH_PREFIX%\dll\x64"
set "_BINNAME=pthreadVC2.dll"
set "_INCPATH=%PTH_PREFIX%\include"
set "_INCNAME=pthread.h"
set "_INCEXT="
set "_LIBPATH=%PTH_PREFIX%\lib\x64"
set "_LIBNAME=pthreadVC2.lib"
set "PTH_PREFIX="

:: --- Note: The code below this block is generic and library-independent. ---

set "TOTAL_ERRORS=0"
set "EXIT_STATUS=1"

:: --- Argument Parsing ---

set "_FORCE="
set "_DO_INSTALL="

:PARSE_ARGS

if "%~1"=="" goto :PARSE_ARGS_DONE
if /I "%~1"=="/f" set "_FORCE=1"
if /I "%~1"=="/i" set "_DO_INSTALL=1"
shift
goto :PARSE_ARGS

:PARSE_ARGS_DONE

:: --- Route based on flags ---

if defined _DO_INSTALL goto :INSTALL_ENV

:: -----------------------------------------------------------------------------
:: --- Main workflow executed when no argument or "/f" is provided.
:: -----------------------------------------------------------------------------

echo:
echo ==========================================================================
echo %INFO% Setting up --- %_LIBRARY% ---
echo %INFO%
echo %WARN% CLI: "%~f0" %*
echo ==========================================================================
echo:

echo ==========================================================================
echo %INFO% %_LIBRARY%: PATH

set "EXIT_STATUS=0"
for %%I in (%_BINNAME%) do (
  set "_MOD=%_BINPATH%\%%~I"
  if exist "!_MOD!" (
    echo %INFO% %_LIBRARY%:   Library "!_MOD!" found.
  ) else (
    echo %ERROR% %_LIBRARY%:   Library "!_MOD!" NOT found!
    set /a "EXIT_STATUS+=1"
  )
)  
if defined _FORCE (set "EXIT_STATUS=0")
if %EXIT_STATUS% equ 0 (
  echo %INFO% %_LIBRARY%:   "Path=%_BINPATH%;%%Path%%"
  set "Path=%_BINPATH%;%Path%"
) else (
  echo %ERROR% %_LIBRARY%:   PATH NOT UPDATED
)
set /a "TOTAL_ERRORS+=!EXIT_STATUS!"
set "_MOD="
set "EXIT_STATUS="

echo ==========================================================================
echo %INFO% %_LIBRARY%: INCLUDE

set "EXIT_STATUS=0"
for %%I in (%_INCNAME%) do (
  set "_MOD=%_INCPATH%%_INCEXT%\%%~I"
  if exist "!_MOD!" (
    echo %INFO% %_LIBRARY%:   Include "!_MOD!" found.
  ) else (
    echo %ERROR% %_LIBRARY%:   Include "!_MOD!" NOT found!
    set /a "EXIT_STATUS+=1"
  )
)  
if defined _FORCE (set "EXIT_STATUS=0")
if %EXIT_STATUS% equ 0 (
  echo %INFO% %_LIBRARY%:   "INCLUDE=%_INCPATH%;%%INCLUDE%%"
  set "INCLUDE=%_INCPATH%;%INCLUDE%"
) else (
  echo %ERROR% %_LIBRARY%:   INCLUDE NOT UPDATED
)
set /a "TOTAL_ERRORS+=!EXIT_STATUS!"
set "_MOD="
set "EXIT_STATUS="


echo ==========================================================================
echo %INFO% %_LIBRARY%: LIB

set "EXIT_STATUS=0"
for %%I in (%_LIBNAME%) do (
  set "_MOD=%_LIBPATH%\%%~I"
  if exist "!_MOD!" (
    echo %INFO% %_LIBRARY%:   Lib "!_MOD!" found.
  ) else (
    echo %ERROR% %_LIBRARY%:   Lib "!_MOD!" NOT found!
    set /a "EXIT_STATUS+=1"
  )
)  
if defined _FORCE (set "EXIT_STATUS=0")
if %EXIT_STATUS% equ 0 (
  echo %INFO% %_LIBRARY%:   "LIB=%_LIBPATH%;%%LIB%%"
  echo %INFO% %_LIBRARY%:   "LINK=%_LIBNAME% %%LINK%%"
  set "LIB=%_LIBPATH%;%LIB%"
  set "LINK=%_LIBNAME% %LINK%"
) else (
  echo %ERROR% %_LIBRARY%:   LINK NOT UPDATED
)
set /a "TOTAL_ERRORS+=!EXIT_STATUS!"
set "_MOD="
set "EXIT_STATUS="

set "FINAL_EXIT_CODE=%TOTAL_ERRORS%"
goto :CLEANUP
:: ============================================================================
:: ============================================================================
:: ============================================================================


:: ============================================================================ INSTALL_ENV BEGIN
:: ============================================================================
:INSTALL_ENV
:: -----------------------------------------------------------------------------
:: --- Alternative workflow executed when "/i" is provided.
:: -----------------------------------------------------------------------------

echo:
echo %INFO% %_LIBRARY%: SOURCE:      "%_BINPATH%"
echo %INFO% %_LIBRARY%: DESTINATION: "%CONDA_PREFIX%\Library\bin"
echo %INFO% %_LIBRARY%: DLLs:        "%_BINNAME%"
echo:

:: --- Must run from an activated Conda environment. ---

if not defined CONDA_PREFIX (
  echo %ERROR% %_LIBRARY%: Run installation command from an activated Conda environment. Aborting...
  set "FINAL_EXIT_CODE=1"
  goto :CLEANUP
)

:: --- Check if already within the CONDA_PREFIX. ---

if "%_BINPATH%"=="%CONDA_PREFIX%\Library\bin" (
  echo %INFO% %_LIBRARY%: _BINPATH - "%_BINPATH%" is within CONDA_PREFIX - "%CONDA_PREFIX%". Skipping...
  set "FINAL_EXIT_CODE=0"
  goto :CLEANUP
)

:: --- Check if CONDA_PREFIX has conflicting DLLs. ---

set "EXIT_STATUS=0"
for %%I in (%_BINNAME%) do (
  if exist "%CONDA_PREFIX%\Library\bin\%%~I" (
    echo %ERROR% %_LIBRARY%: A conflicting name "%%~I" is present in CONDA_PREFIX.
    set "EXIT_STATUS=1"
  )
  if not exist "%_BINPATH%\%%~I" (
    echo %ERROR% %_LIBRARY%: Source not found: "%_BINPATH%\%%~I".
    set "EXIT_STATUS=1"
  )
)
if not "%EXIT_STATUS%"=="0" (
  echo %ERROR% %_LIBRARY%: Pre-flight checks failed. Aborting...
  set "FINAL_EXIT_CODE=%EXIT_STATUS%"
  goto :CLEANUP
)

:: --- Copy DLLs to CONDA_PREFIX. ---

echo %INFO% %_LIBRARY%: Copying files to "%CONDA_PREFIX%\Library\bin"
set "EXIT_STATUS=0"
for %%I in (%_BINNAME%) do (
  copy /Y "%_BINPATH%\%%~I" "%CONDA_PREFIX%\Library\bin\%%~I" > nul
  if not "!ERRORLEVEL!"=="0" (
    echo %ERROR% %_LIBRARY%: Failed to copy "%_BINPATH%\%%~I" to "%CONDA_PREFIX%\Library\bin\%%~I".
    set "EXIT_STATUS=1"
  ) else (
    echo %INFO% %_LIBRARY%: Copied "%_BINPATH%\%%~I" to "%CONDA_PREFIX%\Library\bin\%%~I".
  )
)
if "%EXIT_STATUS%"=="0" (
  echo %OKOK% %_LIBRARY%: Copy complete.
) else (
  echo %ERROR% %_LIBRARY%: Failed to copy libraries above.
)
set "FINAL_EXIT_CODE=%EXIT_STATUS%"
goto :CLEANUP
:: ============================================================================ 
:: ============================================================================ INSTALL_ENV END


:: ============================================================================ COLOR_SCHEME BEGIN
:: ============================================================================
:COLOR_SCHEME
:: ---------------------------------------------------------------------
:: Color Scheme (with NOCOLOR fallback)
:: ---------------------------------------------------------------------

if defined NOCOLOR (
  set  "INFO= [INFO]  "
  set  "OKOK= [-OK-]  "
  set  "WARN= [WARN]  "
  set "ERROR= [ERROR] "
) else (
  set  "INFO=[100;92m [INFO]  [0m"
  set  "OKOK=[103;94m [-OK-]  [0m"
  set  "WARN=[106;35m [WARN]  [0m"
  set "ERROR=[105;34m [ERROR] [0m"
)

exit /b 0
:: ============================================================================ 
:: ============================================================================ COLOR_SCHEME END


:: ============================================================================ CLEANUP BEGIN
:: ============================================================================
:: --- Clean up; prefer as the primary script exit point ---
:: To exit script, set FINAL_EXIT_CODE and goto CLEANUP

:CLEANUP

set "_LIBRARY="
set "_BINPATH="
set "_BINNAME="
set "_INCPATH="
set "_INCNAME="
set "_LIBPATH="
set "_LIBNAME="

set  "INFO="
set  "OKOK="
set  "WARN="
set "ERROR="
set "_FORCE="
set "_DO_INSTALL="
set "EXIT_STATUS="
set "TOTAL_ERRORS="

:: --- Ensure a valid exit code is always returned ---

if not defined FINAL_EXIT_CODE set "FINAL_EXIT_CODE=1"
exit /b %FINAL_EXIT_CODE%
:: ============================================================================ 
:: ============================================================================ CLEANUP END
