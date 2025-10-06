@echo off

setlocal EnableDelayedExpansion

REM ======================================== Main Block ========================================

:: --- Configuration ---
set REPO=mbuilov/sed-windows
set EXEC=sed.exe
set ASSET_SUFFIX=-x64.exe
set JSON_KEY=browser_download_url
set EXIT_STATUS=0
:: --- End Configuration ---


set PREFIX=
if not "%~1"=="" if exist "%~1" (set PREFIX=%~1)
if not defined PREFIX if exist "%~d0\CACHE" (set PREFIX="%~d0\CACHE")
if not defined PREFIX (set PREFIX=%TEMP%)
set PREFIX=%PREFIX%\sed
if not exist "%PREFIX%" mkdir "%PREFIX%"
if exist "%PREFIX%\sed.exe" (
  echo :========== ========== ========== ========== ==========:
  echo  Using cached "%PREFIX%\sed.exe"
  echo :---------- ---------- ---------- ---------- ----------:
  exit /b 0
)


if not exist "%PREFIX%\sed-windows.json" (
  echo:
  echo [+] Get latest release metadata
  echo:
  curl -s "https://api.github.com/repos/%REPO%/releases/latest" >"%PREFIX%\sed-windows.json"
) else (
  echo:
  echo [+] Using cached release metadata
  echo:
)


echo:
echo [+] Parse release metadata
echo:
set ASSET_URL=
for /f "usebackq delims=" %%I in ("%PREFIX%\sed-windows.json") do (
  set LINE=%%~I
  set LINE=!LINE:":="!
  set LINE=!LINE:",="!
  call :JSON_LINE_PROCESSOR !LINE!
  if not "!ASSET_URL!"=="" goto :META_DONE
)
:META_DONE


if not defined ASSET_URL (
  echo:
  echo [#] Failed to identify sed URL. Aborting...
  echo:
  exit /b 1
)

echo:
echo [+] Downloading sed x64.
echo:
curl -L -o "%PREFIX%\sed.exe" "%ASSET_URL%"


endlocal && exit /b %EXIT_STATUS%

REM ======================================== Main Block End ====================================


REM ======================================== Process Release Metadata Line  ========================================
:: Arguments
::   JSON Response data line with colon and terminal comma removed.
:JSON_LINE_PROCESSOR

set KEY=%~1
set VAL=%~2
if /I not "%KEY%"=="%JSON_KEY%" exit /b 0
if /I not "%VAL:~-8%"=="%ASSET_SUFFIX%" exit /b 0
set ASSET_URL=%VAL%

exit /b %EXIT_STATUS%

REM ======================================== Process Release Metadata Line  End ====================================
