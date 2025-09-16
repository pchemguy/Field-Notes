@echo off


setlocal enabledelayedexpansion


:: ============================================================================
::                          CONFIGURATION
:: ============================================================================

:: --- Set the full URL you want to download ---

set "URL=https://hirensbootcd.org/files/HBCD_PE_x64.iso"

:: --- Paste your full cookie data inside the quotes ---

set "COOKIE_STRING="

set WGET=C:/dev/msys64/usr/bin/wget.exe 
set HEADER_FILE=headers.txt

:: -- See docs next to the download loop below for adjusting MAX_WGET_EXT_RETRIES

set MAX_WGET_EXT_RETRIES=99
set COOKIE_FILE=
REM cookies.txt

:: --- Set the names for your output files ---

set OUTPUT_FILE=
REM HBCD_PE_x64.iso

:: ============================================================================


echo [+] Preparing to download from: %URL%
echo.

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

set WGET_HEADERS=
if not "%COOKIE_STRING%"=="" (
  set WGET_HEADERS=%WGET_HEADERS% --header="Cookie: %COOKIE_STRING%"
)

:: --- Build the --header arguments by parsing the header file ---

echo [+] Parsing headers from %HEADER_FILE%...
for /f "usebackq tokens=1,* delims=:" %%G in ("%HEADER_FILE%") do (
    set header_key=%%G
    set header_value=%%H

    REM Trim the leading space that often follows the colon in header values

    if "!header_value:~0,1!"==" " set header_value=!header_value:~1!

    set WGET_HEADERS=!WGET_HEADERS! --header="!header_key!: !header_value!"
)

echo.
echo [+] Executing wget...

:: --- Execute the final wget command with all parsed headers and cookies ---
:: -c                  : Resumes partial downloads.
:: --max-redirect 20   : Follows up to 20 HTTP redirects.
::
:: The wget retry loop LOOP_WGET_EXT_RETRY primarily targets asset downloads from GitHub.
:: GitHub uses redirect to a URL with a short-lived dynamically generated token.
:: When connection is interrupted due to token expiration, WGET retries to the
:: redirected URL and receives an error response. To refresh the token, the original
:: URL must be used. WGET will only retry automatically using the redirected URL, so
:: the download command needs to be wrapped in an external (with respect to WGET) loop
:: (controlled by MAX_WGET_EXT_RETRIES) to use the original URL. 

set WGET_EXT_RETRY_NUM=1

:LOOP_WGET_EXT_RETRY

if "%WGET_EXT_RETRY_NUM:~1%"=="" (
  set PADDING=-
) else (
  set PADDING=
)
echo ===========================================================================
echo ------------------------- WGET external retry #%WGET_EXT_RETRY_NUM% %PADDING%-------------------------
echo ===========================================================================

"%WGET%" -c --max-redirect 100 --content-disposition --tries=0 --timeout=20 ^
         %LOAD_COOKIES%    ^
         %WGET_HEADERS%    ^
         %OUTPUT_DOCUMENT% ^
         "%URL%"

set EXIT_STATUS=%ErrorLevel%

:: --- Download is complete ---

if %EXIT_STATUS% equ 0 (
  echo.
  echo [v] SUCCESS: Download complete. File saved as %OUTPUT_FILE%.
  endlocal && exit /b %EXIT_STATUS%
)

:: --- Download is failed and no more retries left ---

if %WGET_EXT_RETRY_NUM% equ %MAX_WGET_EXT_RETRIES% (
  echo.
  echo [x] ERROR: The wget command failed. ErrorLevel: "%EXIT_STATUS%"
  endlocal && exit /b %EXIT_STATUS%
)

:: --- Download failed. Attempt to resume download ---

set /a WGET_EXT_RETRY_NUM=%WGET_EXT_RETRY_NUM% + 1

goto :LOOP_WGET_EXT_RETRY
