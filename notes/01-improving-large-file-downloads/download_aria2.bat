@echo off


setlocal enabledelayedexpansion


:: ============================================================================
::                          CONFIGURATION
:: ============================================================================

:: --- Set the full URL you want to download ---

set "URL="

:: --- Paste your full cookie data inside the quotes ---

set "COOKIE_STRING="

:: --- Number of threads for parallel doenload

set THREAD_COUNT=5

:: --- Set the names for your input and output files ---

set CUR_DIR=%CD%
cd /d "%~dp0.."
set ARIA2=%CD%\aria2\aria2c.exe
cd  /d "%CUR_DIR%"

set HEADER_FILE=headers.txt

set COOKIE_FILE=
REM cookies.txt

set "OUTPUT_FILE="
REM rescuezilla-2.6.1-64bit.oracular.iso

set "REFERER="

:: ============================================================================


echo [+] Preparing to download from: %URL%
echo:

if defined OUTPUT_FILE (
  set OUTPUT_DOCUMENT=--output-document "%OUTPUT_FILE%"
) else (
  set OUTPUT_DOCUMENT=
)

:: --- URL ---

if not exist "url.txt" goto :SKIP_LOAD_URL
if defined URL goto :SKIP_LOAD_URL
for /f "usebackq tokens=1,* delims=" %%G in ("url.txt") do (
  set "URL=%%G"
)
:SKIP_LOAD_URL

:: --- Cookies ---

if not exist "cookie_value.txt" goto :SKIP_LOAD_COOKIE_VALUE
if defined COOKIE_STRING goto :SKIP_LOAD_COOKIE_VALUE
for /f "usebackq tokens=1,* delims=" %%G in ("cookie_value.txt") do (
  set "COOKIE_STRING=%%G"
)
:SKIP_LOAD_COOKIE_VALUE

set LOAD_COOKIES=
if not defined COOKIE_STRING (set COOKIE_NOT_SET=1)
if defined COOKIE_NOT_SET (
  if exist "%COOKIE_FILE%" (
    set LOAD_COOKIES=--load-cookies="%COOKIE_FILE%"
    set COOKIE_NOT_SET=
  )
)

set ARIA2_HEADERS=
if defined COOKIE_STRING (
  set ARIA2_HEADERS=%ARIA2_HEADERS% --header="Cookie: %COOKIE_STRING%"
)

:: --- Referer ---

if defined REFERER (
  set ARIA2_HEADERS=%ARIA2_HEADERS% --header="Referer: %REFERER%"
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
