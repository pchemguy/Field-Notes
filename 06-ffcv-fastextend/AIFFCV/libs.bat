@echo off

:: ============================================================================
::  Purpose:
::    Downloads and extracts pthreads and OpenCV native libraries.
::    Activates environment settings for:
::      pthreads, OpenCV, LibJPEG-Turbo
::    (LibJPEG-Turbo is assumed to be installed via a Conda package).
::    Supports caching for large downloads (OpenCV).
::
::  Invocation Modes:
::      /preactivate  - Performs environment pre-initialization
::                      (ignore missing files).
::
::      /activate     - Performs environment initialization.
::
::      /install      - Copies DLL to CONDA_PREFIX.
::
::      (no argument) - Downloads and prepares libraries.
::
::  Notes:
::    - CRITICAL: This script MUST be called by a parent script
::      that has enabled delayed expansion (e.g., SETLOCAL EnableDelayedExpansion).
::
::    - CRITICAL: This script and its sub-scripts modify the caller's
::      environment. They CANNOT use SETLOCAL internally.
::
::    - Requires curl.exe and tar.exe (included in modern Windows 10).
::
::    - Uses color-coded output with ANSI escapes when available.
::      To disable colors, set NOCOLOR=1 before calling this script.
::
::    - No verification of downloads or extracted, possibly partially, files.
::      The script uses download caching, but does not handle interrupted partial
::      downloads. If interrupted, the script will attempt to use defective
::      downloaded file, most likely causing subsequent unconditional extraction
::      failure. If such an error occurs, manually delete defective files, which
::      should be indicated in the error message; then rerun the script.
:: ============================================================================

set "EXIT_STATUS="

:: --- Escape sequence templates for color coded console output ---

call :COLOR_SCHEME

echo:
echo ====================================================================================
echo ====================================================================================
echo == %WARN%                                                            %WARN% ==
echo == %WARN%                    Managing libraries                      %WARN% ==
echo == %WARN%                                                            %WARN% ==
echo == %WARN% CLI: "%~f0" %*
echo ====================================================================================
echo ====================================================================================
echo:

:: --------------------------------------------------------
:: Check for activation
:: --------------------------------------------------------
for %%A in ("/activate" "/preactivate") do (
  if /I "%~1"=="%%~A" goto :ACTIVATE
)

:: --------------------------------------------------------
:: Check for installation
:: --------------------------------------------------------

for %%A in ("/i" "/install") do (
  if /I "%~1"=="%%~A" goto :INSTALL
)

echo:
echo ====================================================================================
echo ====================================================================================
echo == %WARN%                                                            %WARN% ==
echo == %WARN%           Installing libraries - Default location          %WARN% ==
echo == %WARN%                                                            %WARN% ==
echo == %WARN% CLI: "%~f0" %*
echo ====================================================================================
echo ====================================================================================
echo:

:: --------------------------------------------------------
:: Determine cache directory
:: --------------------------------------------------------
set "EXIT_STATUS=0"
if not defined _CACHE call :CACHE_DIR
if not "%ERRORLEVEL%"=="0" set "_CACHE="
if not defined _CACHE (
  echo %ERROR% Failed to set CACHE directory. Aborting...
  set "FINAL_EXIT_CODE=1"
  goto :CLEANUP
)
echo:

:: --------------------------------------------------------
:: Verify availability of curl and tar.
:: --------------------------------------------------------
for %%A in ("curl.exe" "tar.exe") do (
  where %%~A >nul 2>nul || (
    echo %ERROR% "%%~A" not found.
    set "FINAL_EXIT_CODE=1"
    goto :CLEANUP
  )
)

:: --------------------------------------------------------
:: pthreads
:: --------------------------------------------------------
call :PTHREADS_DOWNLOAD
set "FINAL_EXIT_CODE=%ERRORLEVEL%"
if not "%FINAL_EXIT_CODE%"=="0" goto :CLEANUP

:: --------------------------------------------------------
:: OpenCV
:: --------------------------------------------------------
call :OPENCV_DOWNLOAD
set "FINAL_EXIT_CODE=%ERRORLEVEL%"
goto :CLEANUP

:: ============================================================================
:: ============================================================================
:: ============================================================================


:: ============================================================================ ACTIVATE BEGIN
:: ============================================================================
:: ============================================================================
:ACTIVATE

echo:
echo ====================================================================================
echo ====================================================================================
echo == %WARN%                                                            %WARN% ==
echo == %WARN%                    Activating libraries                    %WARN% ==
echo == %WARN%                                                            %WARN% ==
echo == %WARN% CLI: "%~f0" %*
echo ====================================================================================
echo ====================================================================================
echo:

if /I "%~1"=="/preactivate" (
  set "_MODE=/f"
) else (
  set "_MODE="
)
set "EXIT_STATUS=1"
set "TOTAL_ERRORS=0"

:::: --- Conda Environment Activation Settings for %CONDA_PREFIX%\Library ---
::
:::: --- Update INCLUDE if new item has not been added before ---
::
::set "_INCPATH=%__CONDA_PREFIX%\Library\include"
::if "!INCLUDE!"=="!INCLUDE:%_INCPATH%=!" (
::  set "INCLUDE=%_INCPATH%;%INCLUDE%"
::) else (
::  echo %INFO% "%_INCPATH%" already added to %%INCLUDE%%
::)
::set "_INCPATH="
::
:: --- Update LIB if new item has not been added before ---
::
::set "_LIBPATH=%__CONDA_PREFIX%\Library\lib"
::if "!LIB!"=="!LIB:%_LIBPATH%=!" (
::  set "LIB=%_LIBPATH%;%LIB%"
::) else (
::  echo %INFO% "%_LIBPATH%" already added to %%LIB%%
::)
::set "_LIBPATH="

:: --- pthreads ---

if exist "%~dp0pthreads\activate.bat" (
  echo:
  echo %WARN% Activating pthreads library.
  call "%~dp0pthreads\activate.bat" %_MODE%
  set "EXIT_STATUS=!ERRORLEVEL!"
  call :COLOR_SCHEME
) else (
  echo %ERROR% pthreads activation script not found: "%~dp0pthreads\activate.bat".
  set "EXIT_STATUS=1"
)
if not "%EXIT_STATUS%"=="0" (
  echo %ERROR% pthreads activation failed.
) else (
  echo %OKOK% pthreads activation succeeded.
)
set /a "TOTAL_ERRORS+=%EXIT_STATUS%"

:: --- OpenCV ---

if exist "%~dp0opencv\activate.bat" (
  echo:
  echo %WARN% Activating OpenCV library.
  call  "%~dp0opencv\activate.bat" %_MODE%
  set "EXIT_STATUS=!ERRORLEVEL!"
  call :COLOR_SCHEME
) else (
  echo %WARN% OpenCV activation script not found: "%~dp0opencv\activate.bat".
  set "EXIT_STATUS=1"
)
if not "%EXIT_STATUS%"=="0" (
  echo %ERROR% OpenCV activation failed.
) else (
  echo %OKOK% OpenCV activation succeeded.
)
set /a "TOTAL_ERRORS+=%EXIT_STATUS%"

:: --- LibJPEG-Turbo ---

if exist "%~dp0libjpeg-turbo\activate.bat" (
  echo:
  echo %WARN% Activating LibJPEG-Turbo library.
  call "%~dp0libjpeg-turbo\activate.bat" %_MODE%
  set "EXIT_STATUS=!ERRORLEVEL!"
  call :COLOR_SCHEME
) else (
  echo %ERROR% LibJPEG-Turbo activation script not found: "%~dp0libjpeg-turbo\activate.bat".
  set "EXIT_STATUS=1"
)
if not "%EXIT_STATUS%"=="0" (
  echo %ERROR% LibJPEG-Turbo activation failed.
) else (
  echo %OKOK% LibJPEG-Turbo activation succeeded.
)
set /a "TOTAL_ERRORS+=%EXIT_STATUS%"
echo ==========================================================================
echo:

if /I "%_MODE%"=="/f" (
  echo:
  rem                   ----- Mon 10/20/2025 21:03:09.88 -----
  echo:                 ----- %DATE% %TIME% -----
  echo ====================================================================================
  echo ====================================================================================
  echo == %WARN%                                                            %WARN% ==
  echo == %WARN%      File not found errors related to library modules      %WARN% ==
  echo == %WARN%      reported during installation above are expected.      %WARN% ==
  echo == %WARN%                                                            %WARN% ==
  echo ====================================================================================
  echo ====================================================================================
  echo:
)

set "FINAL_EXIT_CODE=%TOTAL_ERRORS%"
goto :CLEANUP
:: ============================================================================
:: ============================================================================
:: ============================================================================ ACTIVATE END


:: ============================================================================ INSTALL BEGIN
:: ============================================================================
:: ============================================================================
:INSTALL

echo:
echo ====================================================================================
echo ====================================================================================
echo == %WARN%                                                            %WARN% ==
echo == %WARN%              Installing libraries to CONDA_PREFIX          %WARN% ==
echo == %WARN%                                                            %WARN% ==
echo == %WARN% CLI: "%~f0" %*
echo ====================================================================================
echo ====================================================================================
echo:

set "EXIT_STATUS=0"

:: --- pthreads ---

if exist "%~dp0pthreads\activate.bat" (
  echo:
  echo %WARN% Installing pthreads library.
  call "%~dp0pthreads\activate.bat" /i
  set "EXIT_STATUS=!ERRORLEVEL!"
  call :COLOR_SCHEME
) else (
  echo %ERROR% pthreads activation script not found: "%~dp0pthreads\activate.bat".
  set "EXIT_STATUS=1"
)
if not "%EXIT_STATUS%"=="0" (
  echo %ERROR% pthreads installation failed.
  exit /b %EXIT_STATUS%
) else (
  echo %OKOK% pthreads installation succeeded.
)

:: --- OpenCV ---

if exist "%~dp0opencv\activate.bat" (
  echo:
  echo %WARN% Installing OpenCV library.
  call  "%~dp0opencv\activate.bat" /i
  set "EXIT_STATUS=!ERRORLEVEL!"
  call :COLOR_SCHEME
) else (
  echo %WARN% OpenCV activation script not found: "%~dp0opencv\activate.bat".
  set "EXIT_STATUS=1"
)
if not "%EXIT_STATUS%"=="0" (
  echo %ERROR% OpenCV installation failed.
  exit /b %EXIT_STATUS%
) else (
  echo %OKOK% OpenCV installation succeeded.
)

:: --- LibJPEG-Turbo ---

if exist "%~dp0libjpeg-turbo\activate.bat" (
  echo:
  echo %WARN% Installing LibJPEG-Turbo library.
  call "%~dp0libjpeg-turbo\activate.bat" /i
  set "EXIT_STATUS=!ERRORLEVEL!"
  call :COLOR_SCHEME
) else (
  echo %ERROR% LibJPEG-Turbo activation script not found: "%~dp0libjpeg-turbo\activate.bat".
  set "EXIT_STATUS=1"
)
if not "%EXIT_STATUS%"=="0" (
  echo %ERROR% LibJPEG-Turbo installation failed.
  exit /b %EXIT_STATUS%
) else (
  echo %OKOK% LibJPEG-Turbo installation succeeded.
)

echo ==========================================================================
echo:

set "FINAL_EXIT_CODE=%EXIT_STATUS%"
goto :CLEANUP
:: ============================================================================
:: ============================================================================
:: ============================================================================ INSTALL END


:: ============================================================================ CLEANUP BEGIN
:: ============================================================================
:CLEANUP

set "INFO="
set "OKOK="
set "WARN="
set "ERROR="
set "EXIT_STATUS="
set "TOTAL_ERRORS="
set "_MODE="

set "_DUMMY="
set "RELEASE_URL="
set "PREFIX="
set "_CD="
set "PTHREADS_ZIP="
set "OPENCV_SFX="
set "PTHREADS_ZIP_PARTIAL="
set "OPENCV_SFX_PARTIAL="

if not defined FINAL_EXIT_CODE set "FINAL_EXIT_CODE=1"
exit /b %FINAL_EXIT_CODE%
:: ============================================================================
:: ============================================================================ CLEANUP END


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


:: ============================================================================ CACHE_DIR BEGIN
:: ============================================================================
:CACHE_DIR
:: --------------------------------------------------------
:: Determine cache directory
:: --------------------------------------------------------
if exist "%_CACHE%" goto :CACHE_DIR_SET
set "_CACHE=%TEMP%"

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
set "EXIT_STATUS=%ERRORLEVEL%"
if exist "%_DUMMY%" set "EXIT_STATUS=1"
if not "%EXIT_STATUS%"=="0" (
  echo %ERROR% Failed to delete test directory "%_DUMMY%".
  echo %ERROR% Expected a full-access at this location "%_CACHE%".
  echo %ERROR% Aborting...
  set "_CACHE="
  exit /b %EXIT_STATUS%
)

md "%_DUMMY%"
set "EXIT_STATUS=%ERRORLEVEL%"
if not exist "%_DUMMY%" set "EXIT_STATUS=1"
if not "%EXIT_STATUS%"=="0" (
  echo %ERROR% Failed to create test directory "%_DUMMY%".
  echo %ERROR% Expected a full-access at this location "%_CACHE%".
  echo %ERROR% Aborting...
  set "_CACHE="
  exit /b %EXIT_STATUS%
)

exit /b 0
:: ============================================================================
:: ============================================================================ CACHE_DIR END


:: ============================================================================ PTHREADS_DOWNLOAD BEGIN
:: ============================================================================
:PTHREADS_DOWNLOAD

echo %WARN% pthreads
:: --------------------------------------------------------
:: Download pthreads
:: --------------------------------------------------------
set "RELEASE_URL=ftp://sourceware.org/pub/pthreads-win32/pthreads-w32-2-9-1-release.zip"
set "PREFIX=%_CACHE%\pthreads"
set "PTHREADS_ZIP=%PREFIX%\pthreads-w32-2-9-1-release.zip"

if not exist "%PREFIX%" md "%PREFIX%"
if not "%ERRORLEVEL%"=="0" (
  echo %ERROR% pthreads: Failed to create "%PREFIX%". Aborting bootstrapping...
)

if exist "%PTHREADS_ZIP%" (
  echo %INFO% pthreads: Using cached "%PTHREADS_ZIP%"
) else (
  echo %INFO% pthreads: Downloading: "%RELEASE_URL%"
  echo %INFO% pthreads: Destination: "%PTHREADS_ZIP%"

  rem --- Download to .part file ---

  set "PTHREADS_ZIP_PARTIAL=%PTHREADS_ZIP%.part"
  curl --fail --retry 3 --retry-delay 2 -L -o "!PTHREADS_ZIP_PARTIAL!" "%RELEASE_URL%"
  set "EXIT_STATUS=!ERRORLEVEL!"
  if not "!EXIT_STATUS!"=="0" (
    echo %ERROR% pthreads: Download failure. Aborting bootstrapping...
    exit /b !EXIT_STATUS!
  )

  rem -- On success, rename to final file ---

  move /Y "!PTHREADS_ZIP_PARTIAL!" "%PTHREADS_ZIP%" >nul
  if not "!ERRORLEVEL!"=="0" (
    echo %ERROR% pthreads: Failed to rename "%PTHREADS_ZIP%". Aborting bootstrapping...
    exit /b !ERRORLEVEL!
  )
)
set "PTHREADS_ZIP_PARTIAL="
set "RELEASE_URL="

:: --------------------------------------------------------
:: Extract pthreads
:: --------------------------------------------------------
echo %INFO% pthreads: Extracting "%PTHREADS_ZIP%".
set "_CD=%CD%"
cd /d "%PREFIX%"
tar -xf "%PTHREADS_ZIP%"
set "EXIT_STATUS=%ERRORLEVEL%"
cd /d "%_CD%"
set "_CD="
if not "%EXIT_STATUS%"=="0" (
  echo %ERROR% pthreads: Extraction failure - "%PTHREADS_ZIP%". Error - "%EXIT_STATUS%".
  echo %ERROR% pthreads: The error may be due to corrupted cached files due to previously
  echo %ERROR% pthreads: interrupted downloads. Try manually deleting "%PTHREADS_ZIP%"
  echo %ERROR% pthreads: and run the script again.
  exit /b %EXIT_STATUS%
) else (
  echo %INFO% pthreads: Extracted from "%PTHREADS_ZIP%".
)

xcopy /H /Y /B /E /Q "%PREFIX%\Pre-built.2\*.*" "%~dp0pthreads" 1>nul
set "EXIT_STATUS=%ERRORLEVEL%"
if not "%EXIT_STATUS%"=="0" (
  echo %ERROR% pthreads: Move failure - "%PREFIX%\Pre-built.2".
  exit /b %EXIT_STATUS%
) else (
  echo %INFO% pthreads: Moved from "%PREFIX%\Pre-built.2".
)

xcopy /H /Y /B /E /Q "%~dp0patched\pthread.h" "%~dp0pthreads\include" 1>nul
set "EXIT_STATUS=%ERRORLEVEL%"
if not "%EXIT_STATUS%"=="0" (
  echo %ERROR% pthreads: Move failure - "%~dp0patched\pthread.h".
  exit /b %EXIT_STATUS%
) else (
  echo %INFO% pthreads: Moved from "%~dp0patched\pthread.h".
)

echo %OKOK% pthreads: Completed.
echo:

exit /b 0
:: ============================================================================
:: ============================================================================ PTHREADS_DOWNLOAD END


:: ============================================================================ OPENCV_DOWNLOAD BEGIN
:: ============================================================================
:OPENCV_DOWNLOAD

echo %WARN% OpenCV
:: --------------------------------------------------------
:: Download OpenCV
:: --------------------------------------------------------
set "RELEASE_URL=https://github.com/opencv/opencv/releases/download/4.6.0/opencv-4.6.0-vc14_vc15.exe"
set "PREFIX=%_CACHE%\OpenCV"
set "OPENCV_SFX=%_CACHE%\OpenCV\opencv-4.6.0-vc14_vc15.exe"

if not exist "%PREFIX%" md "%PREFIX%"
if not "%ERRORLEVEL%"=="0" (
  echo %ERROR% OpenCV: Failed to create "%PREFIX%". Aborting bootstrapping...
)

if exist "%OPENCV_SFX%" (
  echo %INFO% OpenCV: Using cached "%OPENCV_SFX%"
) else (
  echo %INFO% OpenCV: Downloading: "%RELEASE_URL%"
  echo %INFO% OpenCV: Destination: "%OPENCV_SFX%"

  rem --- Download to .part file ---

  set "OPENCV_SFX_PARTIAL=%OPENCV_SFX%.part"
  curl --fail --retry 3 --retry-delay 2 -L -o "!OPENCV_SFX_PARTIAL!" "%RELEASE_URL%"
  set "EXIT_STATUS=!ERRORLEVEL!"
  if not "!EXIT_STATUS!"=="0" (
    echo %ERROR% OpenCV: Download failure. Aborting bootstrapping...
    exit /b !EXIT_STATUS!
  )

  rem -- On success, rename to final file ---

  move /Y "!OPENCV_SFX_PARTIAL!" "%OPENCV_SFX%" >nul
  if not "!ERRORLEVEL!"=="0" (
    echo %ERROR% OpenCV: Failed to rename "%OPENCV_SFX%". Aborting bootstrapping...
    exit /b !ERRORLEVEL!
  )
)
set "OPENCV_SFX_PARTIAL="
set "RELEASE_URL="

:: --------------------------------------------------------
:: Extract OpenCV
:: --------------------------------------------------------

if exist "%PREFIX%\$$EXTRACTED$$" (
  echo %INFO% OpenCV: Using extracted "%OPENCV_SFX%".
  goto :SKIP_OPENCV_EXTRACT
)
echo %INFO% OpenCV: Extracting "%OPENCV_SFX%".
"%OPENCV_SFX%" -y  -o"%PREFIX%"
set "EXIT_STATUS=!ERRORLEVEL!"
if not "%EXIT_STATUS%"=="0" (
  echo %ERROR% OpenCV: Extraction failure - "%OPENCV_SFX%".
  echo %ERROR% OpenCV: The error may be due to corrupted cached files due to previously
  echo %ERROR% OpenCV: interrupted downloads. Try manually deleting "%OPENCV_SFX%"
  echo %ERROR% OpenCV: and run the script again.
  exit /b %EXIT_STATUS%
) else (
  echo: >"%PREFIX%\$$EXTRACTED$$"
  echo %INFO% OpenCV: Extracted from "%OPENCV_SFX%".
)

:SKIP_OPENCV_EXTRACT

xcopy /H /Y /B /E /Q /I "%PREFIX%\opencv\build" "%~dp0opencv\build" 1>nul
set "EXIT_STATUS=!ERRORLEVEL!"
if not "%EXIT_STATUS%"=="0" (
  echo %ERROR% OpenCV: Move failure - "%PREFIX%\opencv\build".
  exit /b %EXIT_STATUS%
) else (
  echo %INFO% OpenCV: Moved from "%PREFIX%\opencv\build".
)

echo %OKOK% OpenCV: Completed.
echo:

exit /b 0
:: ============================================================================
:: ============================================================================ OPENCV_DOWNLOAD END
