@echo off
:: ============================================================================
::  libs.bat
:: ----------------------------------------------------------------------------
::  Purpose:
::    Download and extract required native libraries (pthreads, OpenCV)
::    into project subdirectories using only Windows default tools (curl, tar).
::    Supports caching to avoid redundant downloads.
::
::  Notes:
::    - Requires curl.exe and tar.exe (included in modern Windows 10).
::    - Uses color-coded output with ANSI escapes when available.
::      To disable colors, set NO_COLOR=1 before calling this script.
:: ============================================================================


:: ---------------------------------------------------------------------
:: Color Scheme (with NO_COLOR fallback)
:: ---------------------------------------------------------------------
if defined NO_COLOR (
  set "INFO=[INFO] "
  set "OKOK=[OK] "
  set "WARN=[WARN] "
  set "ERROR=[ERROR] "
) else (
  set  "INFO=[100;92m [INFO]  [0m"
  set  "OKOK=[103;94m -[OK]-  [0m"
  set  "WARN=[106;35m [WARN]  [0m"
  set "ERROR=[105;34m [ERROR] [0m"
)

:: ---------------------------------------------------------------------
:: Determine cache directory
:: ---------------------------------------------------------------------
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

:: ---------------------------------------------------------------------
:: Verify availability of curl and tar
:: ---------------------------------------------------------------------
for %%A in ("curl.exe" "tar.exe") do (
  where %%~A >nul 2>nul || (
    echo %ERROR% "%%~A" not found.
    exit /b 1
  )
)
echo %WARN% The script uses download caching but does not handle interrupted downloads.
echo %WARN% If interrupted, it may use a defective cached file causing extraction failure.
echo %WARN% If such an error occurs, manually delete the defective file indicated below,
echo %WARN% then rerun this script.
echo:

:: ---------------------------------------------------------------------
:: pthreads
:: ---------------------------------------------------------------------
call :PTHREADS_DOWNLOAD
set "EXIT_STATUS=!ERRORLEVEL!"
if not "%EXIT_STATUS%"=="0" goto :MAIN_EXIT

:: ---------------------------------------------------------------------
:: OpenCV
:: ---------------------------------------------------------------------
call :OPENCV_DOWNLOAD
set "EXIT_STATUS=!ERRORLEVEL!"
if not "%EXIT_STATUS%"=="0" goto :MAIN_EXIT


:MAIN_EXIT
:: ---------------------------------------------------------------------
:: Clean up color variables and temporary vars
:: ---------------------------------------------------------------------
set  "INFO="
set  "OKOK="
set  "WARN="
set "ERROR="
set "__CONDA_PREFIX="

exit /b %EXIT_STATUS%
:: ============================================================================


:: ============================================================================ CACHE_DIR BEGIN
:: ============================================================================
:CACHE_DIR
:: Determine cache directory location and validate access
:: ----------------------------------------------------------------------------

if exist "%_CACHE%" (
  goto :CACHE_DIR_SET
) else (
  set "_CACHE=%TEMP%"
)

if exist "%~d0\_CACHE" (
  set "_CACHE=%~d0\CACHE"
  goto :CACHE_DIR_SET
)

if exist "%~dp0_CACHE" (
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
set "_DUMMY=%_CACHE%\$$$_DELETEME_ACCESS_CHECK_$$$"
if exist "%_DUMMY%" rmdir /Q /S "%_DUMMY%" >nul 2>nul
set "EXIT_STATUS=!ERRORLEVEL!"
if exist "%_DUMMY%" set "EXIT_STATUS=1"

if not "!EXIT_STATUS!"=="0" (
  echo %ERROR% Failed to delete test directory "%_DUMMY%".
  echo %ERROR% Expected full access to "%_CACHE%".
  exit /b !EXIT_STATUS!
)

md "%_DUMMY%" >nul 2>nul
set "EXIT_STATUS=!ERRORLEVEL!"
if not exist "%_DUMMY%" set "EXIT_STATUS=1"
if not "!EXIT_STATUS!"=="0" (
  echo %ERROR% Failed to create test directory "%_DUMMY%".
  echo %ERROR% Expected full access to "%_CACHE%".
  exit /b !EXIT_STATUS!
)

echo %INFO% CACHE directory: "%_CACHE%".
exit /b 0
:: ============================================================================ CACHE_DIR END


:: ============================================================================ PTHREADS_DOWNLOAD BEGIN
:: ============================================================================
:PTHREADS_DOWNLOAD
echo %WARN% pthreads
:: ----------------------------------------------------------------------------
:: Download pthreads
:: ----------------------------------------------------------------------------
set "RELEASE_URL=ftp://sourceware.org/pub/pthreads-win32/pthreads-w32-2-9-1-release.zip"
set "PTHREADS_ZIP=%_CACHE%\pthreads\pthreads-w32-2-9-1-release.zip"

set "PREFIX=%_CACHE%\pthreads"
if not exist "%PREFIX%" md "%PREFIX%"
if exist "%PTHREADS_ZIP%" (
  echo %INFO% pthreads: Using cached "%PTHREADS_ZIP%"
) else (
  echo %INFO% pthreads: Downloading: %RELEASE_URL%
  echo %INFO% pthreads: Destination: %PTHREADS_ZIP%
  curl --fail --retry 3 --retry-delay 2 -L -o "%PTHREADS_ZIP%" "%RELEASE_URL%"
  set "EXIT_STATUS=!ERRORLEVEL!"
  if not "!EXIT_STATUS!"=="0" (
    echo %ERROR% pthreads: Download failure. Aborting bootstrapping...
    exit /b !EXIT_STATUS!
  )
)
set "RELEASE_URL="

:: ----------------------------------------------------------------------------
:: Extract pthreads
:: ----------------------------------------------------------------------------
echo %INFO% pthreads: Extracting "%PTHREADS_ZIP%".
set "_CD=%CD%"
cd /d "%PREFIX%"
tar -xf "%PTHREADS_ZIP%"
set "EXIT_STATUS=!ERRORLEVEL!"
cd /d "%_CD%"
set "_CD="
if not "!EXIT_STATUS!"=="0" (
  echo %ERROR% pthreads: Extraction failure - "%PTHREADS_ZIP%".
  echo %ERROR% pthreads: Possible corrupted cache from an interrupted download.
  echo %ERROR% pthreads: Delete "%PTHREADS_ZIP%" and rerun this script.
  exit /b !EXIT_STATUS!
) else (
  echo %INFO% pthreads: Extracted from "%PTHREADS_ZIP%".
)

xcopy /H /Y /B /E /Q "%PREFIX%\Pre-built.2\*.*" "%~dp0pthreads" >nul
set "EXIT_STATUS=!ERRORLEVEL!"
if not "!EXIT_STATUS!"=="0" (
  echo %ERROR% pthreads: Move failure - "%PREFIX%\Pre-built.2".
  exit /b !EXIT_STATUS!
) else (
  echo %INFO% pthreads: Copied binaries from "%PREFIX%\Pre-built.2".
)

xcopy /H /Y /B /E /Q "%~dp0patched\pthread.h" "%~dp0pthreads\include" >nul
set "EXIT_STATUS=!ERRORLEVEL!"
if not "!EXIT_STATUS!"=="0" (
  echo %ERROR% pthreads: Move failure - "%~dp0patched\pthread.h".
  exit /b !EXIT_STATUS!
) else (
  echo %INFO% pthreads: Copied patched header "%~dp0patched\pthread.h".
)

echo %OKOK% pthreads: Completed.
echo:
exit /b 0
:: ============================================================================ PTHREADS_DOWNLOAD END


:: ============================================================================ OPENCV_DOWNLOAD BEGIN
:: ============================================================================
:OPENCV_DOWNLOAD
echo %WARN% OpenCV
:: ----------------------------------------------------------------------------
:: Download OpenCV
:: ----------------------------------------------------------------------------
set "RELEASE_URL=https://github.com/opencv/opencv/releases/download/4.6.0/opencv-4.6.0-vc14_vc15.exe"
set "OPENCV_SFX=%_CACHE%\OpenCV\opencv-4.6.0-vc14_vc15.exe"

set "PREFIX=%_CACHE%\OpenCV"
if not exist "%PREFIX%" md "%PREFIX%"
if exist "%OPENCV_SFX%" (
  echo %INFO% OpenCV: Using cached "%OPENCV_SFX%"
) else (
  echo %INFO% OpenCV: Downloading: %RELEASE_URL%
  echo %INFO% OpenCV: Destination: %OPENCV_SFX%
  curl --fail --retry 3 --retry-delay 2 -L -o "%OPENCV_SFX%" "%RELEASE_URL%"
  set "EXIT_STATUS=!ERRORLEVEL!"
  if not "!EXIT_STATUS!"=="0" (
    echo %ERROR% OpenCV: Download failure. Aborting bootstrapping...
    exit /b !EXIT_STATUS!
  )
)
set "RELEASE_URL="

:: ----------------------------------------------------------------------------
:: Extract OpenCV
:: ----------------------------------------------------------------------------
echo %INFO% OpenCV: Extracting "%OPENCV_SFX%".
set "_CD=%CD%"
cd /d "%PREFIX%"
"%OPENCV_SFX%" -o -y
set "EXIT_STATUS=!ERRORLEVEL!"
cd /d "%_CD%"
set "_CD="
if not "!EXIT_STATUS!"=="0" (
  echo %ERROR% OpenCV: Extraction failure - "%OPENCV_SFX%".
  echo %ERROR% OpenCV: Possibly corrupted cached file. Delete it and retry.
  exit /b !EXIT_STATUS!
) else (
  echo %INFO% OpenCV: Extracted from "%OPENCV_SFX%".
)

xcopy /H /Y /B /E /Q /I "%PREFIX%\opencv\build" "%~dp0opencv\build" >nul
set "EXIT_STATUS=!ERRORLEVEL!"
if not "!EXIT_STATUS!"=="0" (
  echo %ERROR% OpenCV: Copy failure - "%PREFIX%\opencv\build".
  exit /b !EXIT_STATUS!
) else (
  echo %INFO% OpenCV: Copied from "%PREFIX%\opencv\build".
)

echo %OKOK% OpenCV: Completed.
echo:
exit /b 0
:: ============================================================================ OPENCV_DOWNLOAD END
