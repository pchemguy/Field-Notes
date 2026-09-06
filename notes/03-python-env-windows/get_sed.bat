@echo off


:HELP
REM ###################################################################################
if /I not "%~1"=="--help" goto :SKIP_HELP
echo:
echo ================================================================================
echo GNU sed Bootstrap Utility {x64}
echo:
echo --------------------------------
echo Purpose     : Download and cache GNU sed (x64) for Windows. Optionally jq (x64).
echo Repository  : https://github.com/mbuilov/sed-windows
echo --------------------------------
echo:
echo Usage:
echo   get_sed.bat [--with-jq] [cache_directory]
echo:
echo Options:
echo   --with-jq    Also download jq.exe {x64}
echo   --help       Show this help message
echo:
echo Exit Codes:
echo   0 - Success
echo   1 - Metadata download failure
echo   2 - URL extraction failure
echo   3 - sed.exe download failure
echo   4 - jq.exe download failure
echo   5 - Cache directory access failure
echo ================================================================================
echo:
set "EXIT_STATUS=0" & goto :EXIT_SED
REM ###################################################################################

:SKIP_HELP
setlocal EnableDelayedExpansion
title GNU sed Bootstrap Utility (x64)

echo:
echo [INFO] Setting sed ...

:: --------------------------------------------------------
:: Parse arguments
:: --------------------------------------------------------
set "EXIT_STATUS=0"
set "WITH_JQ="
if /I "%~1"=="--with-jq" set "WITH_JQ=1" & shift
if /I "%~2"=="--with-jq" set "WITH_JQ=1"
if not "%~1"=="" if exist "%~1" (set "PREFIX=%~1")

:: --------------------------------------------------------
:: Determine cache directory
:: --------------------------------------------------------
if not defined PREFIX if exist "%~d0\CACHE" (set "PREFIX=%~d0\CACHE")
if not defined PREFIX (set "PREFIX=%TEMP%")

if not exist "%PREFIX%\sed" mkdir "%PREFIX%\sed" >nul 2>&1
if not %ERRORLEVEL% equ 0 (
  echo [ERROR] Failed to access cache directory "%PREFIX%\sed".
  set "EXIT_STATUS=5" & goto :EXIT_SED
)
echo [INFO] Using cache folder: "%PREFIX%\sed".

:: --------------------------------------------------------
:: Download jq (if requested)
:: --------------------------------------------------------
if not defined WITH_JQ goto :SKIP_JQ
call :GET_JQ "%PREFIX%" & set "EXIT_STATUS=%ERRORLEVEL%"
if not %EXIT_STATUS% equ 0 goto :EXIT_SED
:SKIP_JQ

:: --------------------------------------------------------
:: Use cached sed if available
:: --------------------------------------------------------
set "SED_EXE=%PREFIX%\sed\sed.exe"
if exist "%SED_EXE%" (
  echo [INFO] Using cached "%SED_EXE%"
  set "EXIT_STATUS=0" & goto :EXIT_SED
)

:: --------------------------------------------------------
:: Fetch release metadata
:: --------------------------------------------------------
set "REPO=mbuilov/sed-windows"
set "META_FILE=%PREFIX%\sed\sed-windows.json"
if exist "%META_FILE%" (
  echo [INFO] Using cached release metadata "%META_FILE%".
  goto :SKIP_SED_META
)
echo [INFO] Fetching latest release metadata...
curl -s "https://api.github.com/repos/%REPO%/releases/latest" >"%META_FILE%"
if not %ERRORLEVEL% equ 0 (
  echo [ERROR] Failed to download metadata.
  set "EXIT_STATUS=1" & goto :EXIT_SED
)
:SKIP_SED_META

:: --------------------------------------------------------
:: Extract asset URL (prefer jq, fallback Findstr)
:: --------------------------------------------------------
set "JQ="
where jq.exe >nul 2>&1 && set "JQ=jq.exe"
if not defined JQ if exist "%PREFIX%\jq\jq.exe" set "JQ=%PREFIX%\jq\jq.exe"
if not defined JQ (
  echo [INFO] JQ is not available. Consider using --with-jq flag.
  goto :FINDSTR_ASSET_URL
)

:: --- Use JQ, if available ---

echo [INFO] Parsing sed JSON metadata with JQ
set "ASSET_URL="
set "ASSET_SUFFIX=x64.exe"
set "PATTERN=.assets[] | select(.browser_download_url | test(""x64\\.exe$"")) | .browser_download_url"
"%JQ%"  -r "%PATTERN%" "%META_FILE%" >"%TEMP%\ASSET_URL.txt"
for /f "usebackq delims=" %%A in ("%TEMP%\ASSET_URL.txt") do set "ASSET_URL=%%A"
del /Q "%TEMP%\ASSET_URL.txt"
goto :SKIP_FINDSTR_ASSET_URL

:FINDSTR_ASSET_URL
:: --- Findstr fallback ---

echo [INFO] Parsing sed JSON metadata with FINDSTR
set "PATTERN=^[ ]*.browser_download_url.:[ ]*https://github.com/%REPO%/releases/download/[^/]*/sed[^/]*-x64\.exe"
for /f "usebackq tokens=2 delims=, " %%A in (`findstr /R /I "%PATTERN%" "%META_FILE%"`) do (
  set "ASSET_URL=%%~A"
)

:SKIP_FINDSTR_ASSET_URL

if not defined ASSET_URL (
  echo [ERROR] Could not locate sed download URL.
  set "EXIT_STATUS=2" & goto :EXIT_SED
)
echo [INFO] Using asset URL !ASSET_URL! 


:: --------------------------------------------------------
:: Download sed
:: --------------------------------------------------------
echo [INFO] Downloading sed (x64)...
curl --fail --retry 3 --retry-delay 2 -L -o "%SED_EXE%" "%ASSET_URL%"
if not %ERRORLEVEL% equ 0 (
  echo [ERROR] sed.exe download failed.
  set "EXIT_STATUS=3" & goto :EXIT_SED
)

set "EXIT_STATUS=0"
echo -[OK]- sed.exe successfully downloaded to "%PREFIX%\sed"
echo:

:EXIT_SED
endlocal & exit /b %EXIT_STATUS%


REM ################################################################################
REM ################################################################################
REM ################################################################################


:GET_JQ
@echo off

REM ================================================================================
REM  SUBROUTINE: GET_JQ
REM  Purpose: Download and cache jq.exe (x64) from its stable release URL.
REM ================================================================================

setlocal EnableDelayedExpansion
title Download jq.exe for Windows

echo:
echo [INFO] Setting jq ...

:: --------------------------------------------------------
:: Parse arguments
:: --------------------------------------------------------
if not "%~1"=="" if exist "%~1" (set "PREFIX=%~1")

set "EXIT_STATUS=0"

:: --------------------------------------------------------
:: Determine cache directory
:: --------------------------------------------------------
if not defined PREFIX if exist "%~d0\CACHE" (set "PREFIX=%~d0\CACHE")
if not defined PREFIX (set "PREFIX=%TEMP%")
if not exist "%PREFIX%\jq" mkdir "%PREFIX%\jq" >nul 2>&1
if not %ERRORLEVEL% equ 0 (
  echo [ERROR] Failed to access cache directory "%PREFIX%\jq".
  set "EXIT_STATUS=5" & goto :EXIT_JQ
)
echo [INFO] Using cache folder: "%PREFIX%\jq".

:: --------------------------------------------------------
:: Use cached jq if available
:: --------------------------------------------------------
set "JQ_EXE=%PREFIX%\jq\jq.exe"
if exist "%JQ_EXE%" (
  echo [INFO] Using cached "%JQ_EXE%"
  set "EXIT_STATUS=0" & goto :EXIT_JQ
)

:: --------------------------------------------------------
:: Download jq
:: --------------------------------------------------------
echo [INFO] Downloading jq.exe...
set "RELEASE_URL=https://github.com/jqlang/jq/releases/latest/download/jq-win64.exe"
curl --fail --retry 3 --retry-delay 2 -L -o "%JQ_EXE%" "%RELEASE_URL%"
if not %ERRORLEVEL% equ 0 (
  echo [ERROR] jq.exe download failed.
  set "EXIT_STATUS=4" & goto :EXIT_JQ
)

set "EXIT_STATUS=0"
echo -[OK]- jq.exe successfully downloaded to "%PREFIX%\jq"
echo:

:EXIT_JQ
endlocal & exit /b %EXIT_STATUS%
