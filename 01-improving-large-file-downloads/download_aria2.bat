@echo off


setlocal enabledelayedexpansion


:: ============================================================================
::                          CONFIGURATION
:: ============================================================================

:: --- Set the full URL you want to download ---

set "URL=https://github.com/rescuezilla/rescuezilla/releases/download/2.6.1/rescuezilla-2.6.1-64bit.oracular.iso"

:: --- Paste your full cookie data inside the quotes ---

set "COOKIE_STRING="

:: --- Number of threads for parallel doenload

set THREAD_COUNT=2

:: --- Set the names for your input and output files ---

set ARIA2=B:/GPU Comp/DM/aria2/aria2c.exe
set HEADER_FILE=headers.txt

set COOKIE_FILE=
REM cookies.txt

set OUTPUT_FILE=
REM rescuezilla-2.6.1-64bit.oracular.iso

:: ============================================================================


echo [+] Preparing to download from: %URL%
echo:

:: --- Custom options and headers ---

if not "%OUTPUT_FILE%"=="" (
  set OUTPUT_DOCUMENT=--output-document "%OUTPUT_FILE%"
) else (
  set OUTPUT_DOCUMENT=
)
if "%COOKIE_STRING%"=="" (
  if not "%COOKIE_FILE%"=="" (
    set LOAD_COOKIES=--load-cookies="%COOKIE_FILE%"
  ) else (
    set LOAD_COOKIES=
  )
)

set ARIA2_HEADERS=
if not "%COOKIE_STRING%"=="" (
  set ARIA2_HEADERS=%ARIA2_HEADERS% --header="Cookie: %COOKIE_STRING%"
)

:: --- Build the --header arguments by parsing the header file ---

echo [+] Parsing headers from %HEADER_FILE%...
for /f "usebackq tokens=1,* delims=:" %%G in ("%HEADER_FILE%") do (
    set header_key=%%G
    set header_value=%%H

    REM Trim the leading space that often follows the colon in header values

    if "!header_value:~0,1!"==" " set header_value=!header_value:~1!

    set ARIA2_HEADERS=!ARIA2_HEADERS! --header="!header_key!: !header_value!"
)

echo:
echo [+] Executing aria2...
"%ARIA2%" -c --max-tries=20 --timeout=20 --file-allocation=none ^
          --max-connection-per-server=%THREAD_COUNT% --split=%THREAD_COUNT% ^
          %LOAD_COOKIES%    ^
          %ARIA2_HEADERS%   ^
          %OUTPUT_DOCUMENT% ^
          "%URL%"

set EXIT_STATUS=%ErrorLevel%

if %EXIT_STATUS% equ 0 (
  set MSG=[v] SUCCESS: Download complete. File saved as %OUTPUT_FILE%.
) else (
  set MSG=[x] ERROR: The aria2 command failed. ErrorLevel: "%EXIT_STATUS%"
)

echo:
echo %MSG%
endlocal && exit /b %EXIT_STATUS%
