@echo off

Title Download latest GitHub Release

goto :SKIP_HELP

:HELP
echo:
echo %HH_BEG% ################################################################################# %ESC_RST%
echo %H_PREF% Cached download of the latest binary release from GitHub.
echo %H_PREF% 
echo %H_PREF% -----------------------------------------------------------------------------
echo %H_PREF% Usage:
echo %H_PREF%   Set relevant variables and execute script. No command line interface at present.
echo %H_PREF%   IMPORTANT: AVOID EXECUTING THIS SCRIPT WITH ADMIN PRIVILEGES^^!
echo %H_PREF%   Example:  
echo %H_PREF%     set "COMMON_NAME=PIXI"
echo %H_PREF%     set "REPO_NAME=prefix-dev/pixi"
echo %H_PREF%     set "ASSET_URL_SUFFIX="
echo %H_PREF%     set "RELEASE_URL_SUFFIX=pixi-x86_64-pc-windows-msvc.zip"
echo %H_PREF%     set "DOWNLOAD_EXT="
echo %H_PREF%     set "CANONICAL_NAME=pixi.exe"
echo %H_PREF%     set "SPECIFIC_NAME=pixi.exe"
echo %H_PREF%     set "EXE_NAME="
echo %H_PREF%     call GitHubRelease.bat
echo %H_PREF%
echo %H_PREF%   See also "GitHubRelease_Test.bat"
echo %H_PREF% -----------------------------------------------------------------------------
echo %H_PREF% 
echo %H_PREF% Description:
echo %H_PREF%   Cached downlad of the latest binary release from GitHub. If previously
echo %H_PREF%   downloaded, use the cached version.
echo %H_PREF% 
echo %H_PREF%   - Considers two type of release access regarding filename URL suffix:
echo %H_PREF%     - Does not include version number,- direct version-independent URL.
echo %H_PREF%     - Includes version number - actual download URL must be obtained by
echo %H_PREF%       querying and analyzing release metadata.
echo %H_PREF%   - Considers two types of release formats:
echo %H_PREF%     - EXE - no further actions are required.
echo %H_PREF%     - ZIP - untar and, potentially rename executable.
echo %H_PREF% 
echo %H_PREF% Requirements:
echo %H_PREF%   tar.exe and curl.exe.
echo %H_PREF% -----------------------------------------------------------------------------
echo %H_PREF% 
echo %H_PREF% Variables (no quotes in values):
echo %H_PREF%   COMMON_NAME          - e.g., "JQ" - used for labeling console output and CACHE
echo %H_PREF%                                       directory name.
echo %H_PREF%   REPO_NAME            - e.g., "jqlang/jq"
echo %H_PREF%   RELEASE_URL_SUFFIX   - e.g., "micromamba-win-64", "jq-win64.exe",
echo %H_PREF%                                "pixi-x86_64-pc-windows-msvc.zip"
echo %H_PREF%   DOWNLOAD_EXT         - e.g.,  ".exe"
echo %H_PREF%   ASSET_URL_SUFFIX     - e.g., "x64.exe" - must be unset for direct links and set
echo %H_PREF%                                            for metadata queries.
echo %H_PREF%   CANONICAL_NAME       - e.g., "jq.exe" - rename downloaded/extracted file.
echo %H_PREF%   SPECIFIC_NAME        - e.g., "jq-x64.exe" - if defined, used to identify file
echo %H_PREF%                                               to be renamed. Otherwise - guess.
echo %H_PREF%                        
echo %H_PREF%   EXE_NAME             - computed, is set to absolute executable path.
echo %H_PREF%                        
echo %H_PREF%   UPDATE_CACHE         - flag, if defined, existing cache is deleted (except for JQ).
echo %H_PREF%   NO_TOP_BAR           - flag, if defined, skips top bar in console output.
echo %H_PREF%   NO_BOTTOM_BAR        - flag, if defined, skips bottom bar in console output.
echo %H_PREF%   ESCAPE_COLORS_SILENT - flag, if defined, suppresses ESCAPE_COLORS confirmation.
echo %H_PREF%   BLOCK_TYPE           - selects block label style. Presently can be left set to
echo %H_PREF%                          "ODD" (default, same as undefined) or "EVEN".
echo %H_PREF% -----------------------------------------------------------------------------
echo %H_PREF% 
echo %H_PREF% NOTE:
echo %H_PREF%   - INDIRECT downloads primarily uses ASSET_URL_SUFFIX and not RELEASE_URL_SUFFIX.
echo %H_PREF%     Assumes that direct link is provided in the "browser_download_url" field 
echo %H_PREF%     of the release metadata. Specific URL is extracted using the specified 
echo %H_PREF%     ASSET_URL_SUFFIX to perform string matching. RELEASE_URL_SUFFIX should 
echo %H_PREF%     still be set to define downloaded file name (curl does not guess file 
echo %H_PREF%     name and this code presently does not parse extracted ASSET_URL either.
echo %H_PREF%   - DIRECT downloads uses RELEASE_URL_SUFFIX to construct download URL.
echo %H_PREF%   - Uses ANSI escape sequences for output highlighting.
echo %H_PREF%   - Uses stringed "endlocal" with returned variable set, when necessary.
echo %H_PREF% -----------------------------------------------------------------------------
echo %HH_BEG% ################################################################################# %ESC_RST%
echo:
endlocal & exit /b 0

:SKIP_HELP

call :ESCAPE_COLORS

for %%A in ("--help" "-help" "-h" "/?") do (
  if /I "%~1"=="%%~A" goto :HELP
)

:: /************************************************************************************************************/ MAIN BEGIN
:: /************************************************************************************************************/ 
:MAIN
if not defined NO_TOP_BAR (
  echo:
  echo %ESC%%BG_AUX%;97m ============================================================================ %ESC_RST%
  echo %ESC%%BG_BEG%;94m ================================ BEGIN MAIN ================================ %ESC_RST%
  echo %ESC%%BG_AUX%;97m ============================================================================ %ESC_RST%
  echo:
)
SetLocal EnableExtensions EnableDelayedExpansion
set EXIT_STATUS=0

:: --- Verify availablity of curl and tar.

for %%A in ("curl.exe" "tar.exe") do (
  where %%~A >nul 2>nul || (
    echo %ERROR% "%%~A" not found.
    exit /b 1
  )
)

if not defined CACHE (
  call :CACHE_DIR & set "EXIT_STATUS=!ERRORLEVEL!"
)

if not defined JQ (
  call :JQ_DOWNLOAD & set "EXIT_STATUS=!ERRORLEVEL!"
  if not %EXIT_STATUS% equ 0 goto :MAIN_EXIT
  echo:
  echo %INFO% JQ = "!JQ!"
)

if defined REPO_NAME (
  rem ::
  rem :: --- Set externally ---
  rem ::
  call :ASSET_DOWNLOAD & set "EXIT_STATUS=!ERRORLEVEL!"
  goto :MAIN_EXIT
) else (
  rem ::
  rem :: --- Self-Testing ---
  rem ::
  call :PIXI_DOWNLOAD & set "EXIT_STATUS=!ERRORLEVEL!"
  if not !EXIT_STATUS! equ 0 goto :MAIN_EXIT
  call :SED_DOWNLOAD & set "EXIT_STATUS=!ERRORLEVEL!"
  if not !EXIT_STATUS! equ 0 goto :MAIN_EXIT
  call :LIBJPEG_TURBO_DOWNLOAD & set "EXIT_STATUS=!ERRORLEVEL!"
  if not !EXIT_STATUS! equ 0 goto :MAIN_EXIT
)

:MAIN_EXIT
if %EXIT_STATUS% equ 0 (
  set BG_END=%BG_OKI%
) else (
  set BG_END=%BG_ERR%
)
if not defined NO_BOTTOM_BAR (
  echo:
  echo %ESC%%BG_AUX%;97m  ============================================================================ %ESC_RST%
  echo %ESC%%BG_END%;94m  ================================= END MAIN ================================= %ESC_RST%
  echo %ESC%%BG_AUX%;97m  ============================================================================ %ESC_RST%
  echo:
)
EndLocal & (set "JQ=%JQ%") & (set "CACHE=%CACHE%") & exit /b %EXIT_STATUS%
:: /************************************************************************************************************/ MAIN END
:: /************************************************************************************************************/ 


:: ============================================================================ ESCAPE_COLORS BEGIN
:: ============================================================================
:ESCAPE_COLORS
:: --------------------------------------------------------
:: Set label colors via ANSI escape sequences.
:: --------------------------------------------------------

set "ESC=["
set "ESC_RST=[0m"
set BG_AUX=100
set BG_BEG=103
set BG_ERR=101
set BG_OKI=106
set BG_ODD_BLOCK=42
set BG_EVEN_BLOCK=46
set BG_HELP_FRAME=44

set "HH_BEG=%ESC%%BG_HELP_FRAME%m"
set "H_PREF=%HH_BEG% ## %ESC_RST%"

set  "INFO=%ESC%%BG_AUX%;92m [INFO]  %ESC_RST%"
set  "OKOK=%ESC%%BG_BEG%;94m -[OK]-  %ESC_RST%"
set  "WARN=%ESC%%BG_OKI%;35m [WARN]  %ESC_RST%"
set "ERROR=%ESC%%BG_ERR%;34m [ERROR] %ESC_RST%"

rem echo %INFO% INFORMATION
rem echo %OKOK% OK
rem echo %WARN% WARNING
rem echo %ERROR% ERROR

if not defined ESCAPE_COLORS_SILENT (
  echo:
  echo %INFO% Set escape sequence templates for color labels.
  echo:
)

exit /b 0
:: ============================================================================
:: ============================================================================ ESCAPE_COLORS END


:: ============================================================================ CACHE_DIR BEGIN
:: ============================================================================
:CACHE_DIR
:: --------------------------------------------------------
:: Determine cache directory
:: --------------------------------------------------------
if exist "%CACHE%" (
  goto :CACHE_DIR_SET
) else (
  set "CACHE=%TEMP%"
)

if exist "%~d0\CACHE" (
  set "CACHE=%~d0\CACHE"
  goto :CACHE_DIR_SET
)

if exist "%~dp0CACHE" (
  set "CACHE=%~dp0CACHE"
  goto :CACHE_DIR_SET
)

if exist "%USERPROFILE%\Downloads" (
  if exist "%USERPROFILE%\Downloads\CACHE" (
    set "CACHE=%USERPROFILE%\Downloads\CACHE"
  ) else (
    set "CACHE=%USERPROFILE%\Downloads"
  )
  goto :CACHE_DIR_SET
)

:CACHE_DIR_SET
echo %INFO% CACHE directory: "!CACHE!".

exit /b 0
:: ============================================================================
:: ============================================================================ CACHE_DIR END


:: ============================================================================ JQ_DOWNLOAD BEGIN
:: ============================================================================
:JQ_DOWNLOAD
:: --------------------------------------------------------
:: Download and cache the latest jq.exe (x64) from GitHub.
:: Note: used for parsing GitHub release JSON metadata.
:: --------------------------------------------------------

setlocal

set "BLOCK_TYPE=EVEN"

:: --- JQ as a tool is excluded from UPDATE_CACHE flag. If necessary, delete local cache manually. ---

set "UPDATE_CACHE="

set "COMMON_NAME=JQ"
set "REPO_NAME=jqlang/jq"
REM - Direct download
set "ASSET_URL_SUFFIX="
set "RELEASE_URL_SUFFIX=jq-win64.exe"
REM - File extension in URL.
set "DOWNLOAD_EXT="
set "CANONICAL_NAME=jq.exe"
rem Use old file name from URL
set "SPECIFIC_NAME="

call :ASSET_DOWNLOAD & set "EXIT_STATUS=%ERRORLEVEL%"

endlocal & (set "JQ=%EXE_NAME%") & exit /b %EXIT_STATUS%
:: ============================================================================
:: ============================================================================ JQ_DOWNLOAD END


:: ============================================================================ PIXI_DOWNLOAD BEGIN
:: ============================================================================
:PIXI_DOWNLOAD
:: --------------------------------------------------------
:: Download and cache the latest jq.exe (x64) from GitHub.
:: Note: FOR TESTING ONLY.
:: --------------------------------------------------------

setlocal

set "COMMON_NAME=PIXI"
set "REPO_NAME=prefix-dev/pixi"
REM - Direct download
set "ASSET_URL_SUFFIX="
set "RELEASE_URL_SUFFIX=pixi-x86_64-pc-windows-msvc.zip"
REM - File extension in URL.
set "DOWNLOAD_EXT="
set "CANONICAL_NAME=pixi.exe"
rem Use old file name from URL
set "SPECIFIC_NAME=pixi.exe"

call :ASSET_DOWNLOAD & set "EXIT_STATUS=%ERRORLEVEL%"

endlocal & exit /b %EXIT_STATUS%
:: ============================================================================
:: ============================================================================ PIXI_DOWNLOAD END


:: ============================================================================ SED_DOWNLOAD BEGIN
:: ============================================================================
:SED_DOWNLOAD
:: --------------------------------------------------------
:: Download and cache the latest sed.exe (x64) from GitHub.
:: Note: FOR TESTING ONLY.
:: --------------------------------------------------------

setlocal

set "COMMON_NAME=SED"
set "REPO_NAME=mbuilov/sed-windows"
REM - Direct download
set "ASSET_URL_SUFFIX=x64.exe"
set "RELEASE_URL_SUFFIX=sed.exe"
REM - File extension in URL.
set "DOWNLOAD_EXT="
set "CANONICAL_NAME=sed.exe"
rem Use old file name from URL
set "SPECIFIC_NAME="

call :ASSET_DOWNLOAD & set "EXIT_STATUS=%ERRORLEVEL%"

endlocal & exit /b %EXIT_STATUS%
:: ============================================================================
:: ============================================================================ SED_DOWNLOAD END


:: ============================================================================ LIBJPEG_TURBO_DOWNLOAD BEGIN
:: ============================================================================
:LIBJPEG_TURBO_DOWNLOAD
:: --------------------------------------------------------
:: Download and cache the latest libjpeg-turbo from GitHub.
:: Note: FOR TESTING ONLY.
:: --------------------------------------------------------

setlocal

set "COMMON_NAME=libjpeg-turbo"
set "REPO_NAME=libjpeg-turbo/libjpeg-turbo"
REM - Direct download
set "ASSET_URL_SUFFIX=vc-x64.exe"
set "RELEASE_URL_SUFFIX=libjpeg-turbo-vc-x64.exe"
REM - File extension in URL.
set "DOWNLOAD_EXT="
set "CANONICAL_NAME="
rem Use old file name from URL
set "SPECIFIC_NAME="

call :ASSET_DOWNLOAD & set "EXIT_STATUS=%ERRORLEVEL%"

endlocal & exit /b %EXIT_STATUS%
:: ============================================================================
:: ============================================================================ LIBJPEG_TURBO_DOWNLOAD END


:: ============================================================================ ASSET_DOWNLOAD BEGIN
:: ============================================================================
:ASSET_DOWNLOAD
:: --------------------------------------------------------
:: Download and cache the latest GitHub release.
:: --------------------------------------------------------

if not defined BLOCK_TYPE (
  set "BLCK_LBL=%ESC%%BG_ODD_BLOCK%m %COMMON_NAME% %ESC_RST%"
)
if /I "%BLOCK_TYPE%"=="ODD" (
  set "BLCK_LBL=%ESC%%BG_ODD_BLOCK%m %COMMON_NAME% %ESC_RST%"
)
if /I "%BLOCK_TYPE%"=="EVEN" (
  set "BLCK_LBL=%ESC%%BG_EVEN_BLOCK%m %COMMON_NAME% %ESC_RST%"
)

echo:
echo %INFO% %BLCK_LBL%: Download, if not cached...

:: --- If UPDATE_CACHE defined, delete existing cache.

set "PREFIX=%CACHE%\%COMMON_NAME%"
if defined UPDATE_CACHE (
  if exist "%PREFIX%" (
    echo %INFO% %BLCK_LBL%: Existing cache "%PREFIX%" found. Cache update flag is set. Attempting to delete...
    rmdir /S /Q "%PREFIX%"
    set "EXIT_STATUS=!ERRORLEVEL!"
  )
  if not !EXIT_STATUS! equ 0 (
    set "ERR_MSG=Failed to clear cached "%PREFIX%". Aborting download..."
    echo %ERROR% %BLCK_LBL%: !ERR_MSG! 
    exit /b !EXIT_STATUS!
  ) else (
    echo %INFO% %BLCK_LBL%: Deleted existing cache "%PREFIX%".
  )
)
if not exist "%PREFIX%" (
  md "%PREFIX%" & set "EXIT_STATUS=!ERRORLEVEL!"
  if not !EXIT_STATUS! equ 0 (
    set "ERR_MSG=Failed to create prefix: "%PREFIX%". Aborting download..."
    echo %ERROR% %BLCK_LBL%: !ERR_MSG! 
    exit /b !EXIT_STATUS!
  )
)
echo %INFO% %BLCK_LBL%: Prefix "%PREFIX%".

:: --- Determine final exe path ---

set "DOWNLOAD_FILE=%RELEASE_URL_SUFFIX%%DOWNLOAD_EXT%"

if defined CANONICAL_NAME (
  :: --- Use either CANONICAL_NAME ---
  set "EXE_NAME=%PREFIX%\%CANONICAL_NAME%"
) else (
  :: --- or the last part of the url. For zip files, replace ".zip" with ".exe".
  set "EXE_NAME=%PREFIX%\%DOWNLOAD_FILE:~0,-4%.exe"
)

echo %INFO% %BLCK_LBL%: EXE_NAME "%EXE_NAME%"

:: --- Check for cached files ---

if exist "%EXE_NAME%" (
  echo %OKOK% %BLCK_LBL%: Cached "%EXE_NAME%"
  exit /b 0
)

if exist "%PREFIX%\%DOWNLOAD_FILE%" (
  echo %INFO% %BLCK_LBL%: Cached "%PREFIX%\%DOWNLOAD_FILE%"
  goto :SKIP_GITHUB_DOWNLOAD
)

:: --- Download ---

if not defined ASSET_URL_SUFFIX (
  set "ASSET_URL=https://github.com/%REPO_NAME%/releases/latest/download/%RELEASE_URL_SUFFIX%"
) else (
  call :RETRIEVE_ASSET_URL & set "EXIT_STATUS=!ERRORLEVEL!"
  if not !EXIT_STATUS! equ 0 (
    set "ERR_MSG=Failed to retrieve ASSET_URL from GitHub release metadata."
    echo %ERROR% %BLCK_LBL%: !ERR_MSG!
    exit /b !EXIT_STATUS!
  )
)
echo %INFO% %BLCK_LBL%: Downloading %ASSET_URL%.
echo %INFO% %BLCK_LBL%: Destination "%PREFIX%\%DOWNLOAD_FILE%".
curl --fail --retry 3 --retry-delay 2 -L -o "%PREFIX%\%DOWNLOAD_FILE%" "%ASSET_URL%"
set "EXIT_STATUS=!ERRORLEVEL!"
if not %EXIT_STATUS% equ 0 (
  set "ERR_MSG=Failed to download %COMMON_NAME%..."
  echo %ERROR% %BLCK_LBL%: !ERR_MSG!
  exit /b %EXIT_STATUS%
) else (
  echo %INFO% %BLCK_LBL%: Downloaded to "%PREFIX%\%DOWNLOAD_FILE%".
)

:SKIP_GITHUB_DOWNLOAD

:: --- Extract ZIP, if applicable ---

if /I not "%DOWNLOAD_FILE:~-4%"==".zip" (
  echo %INFO% %BLCK_LBL%: "zip" extension not detected, skipping extraction.
  goto :SKIP_ZIP_EXTRACT
)

echo %INFO% %BLCK_LBL%: Extracting "%PREFIX%\%DOWNLOAD_FILE%".
set "_CD=%CD%"
cd /d "%PREFIX%"
tar -xf "%DOWNLOAD_FILE%" & set "EXIT_STATUS=!ERRORLEVEL!"
cd /d "%_CD%" & set set "_CD="
if not !EXIT_STATUS! equ 0 (
  echo %ERROR% %BLCK_LBL%: Extraction failure - "%PREFIX%\%DOWNLOAD_FILE%".
  exit /b !EXIT_STATUS!
) else (
  echo %INFO% %BLCK_LBL%: Extracted from "%PREFIX%\%DOWNLOAD_FILE%".
)

:SKIP_ZIP_EXTRACT

:: --- Rename extracted EXE, if relevant ---

if exist "%EXE_NAME%" goto :DOWNLOAD_COMPLETE
if defined CANONICAL_NAME (
  if not defined SPECIFIC_NAME (
    set "_SPECIFIC_NAME=%DOWNLOAD_FILE:~0,-4%.exe"
  ) else (
    set "_SPECIFIC_NAME=%SPECIFIC_NAME%"
  )
  move "%PREFIX%\!_SPECIFIC_NAME!" "%EXE_NAME%" & set "EXIT_STATUS=!ERRORLEVEL!"
  set "_SPECIFIC_NAME="
  if not !EXIT_STATUS! equ 0 (
    set ERR_MSG=Failed to rename: "%PREFIX%\!_SPECIFIC_NAME!".
    echo %ERROR% %BLCK_LBL%: !ERR_MSG! 
    exit /b !EXIT_STATUS!
  )

)

:DOWNLOAD_COMPLETE

echo %OKOK% %BLCK_LBL%: %COMMON_NAME% is ready as "%EXE_NAME%"
echo:

set ASSET_URL=

exit /b %EXIT_STATUS%
:: ============================================================================
:: ============================================================================ ASSET_DOWNLOAD END


:: ============================================================================ RETRIEVE_ASSET_URL BEGIN
:: ============================================================================
:RETRIEVE_ASSET_URL
:: --------------------------------------------------------
:: Retrieves GitHub release metadata, parses it, extracts asset URL, and sets ASSET_URL
:: --------------------------------------------------------

:: --------------------------------------------------------
:: Fetch release metadata
:: --------------------------------------------------------
set "META_FILE=%PREFIX%\%COMMON_NAME%.json"
echo %INFO% %BLCK_LBL%: Metadata file "%META_FILE%".
if exist "%META_FILE%" (
  echo %INFO% %BLCK_LBL%: Using cached release metadata.
  goto :SKIP_META_FETCH
)

set "META_URL=https://api.github.com/repos/%REPO_NAME%/releases/latest"
echo %INFO% %BLCK_LBL%: Fetching latest release metadata from %META_URL%.
curl --fail --retry 3 --retry-delay 2 -s "%META_URL%" >"%META_FILE%"
set "EXIT_STATUS=!ERRORLEVEL!"
if not %EXIT_STATUS% equ 0 (
  set "ERR_MSG=Failed to download metadata."
  echo %ERROR% %BLCK_LBL%: !ERR_MSG!
  move "%META_FILE%" "%META_FILE:.json=_bad.json%"
  exit /b !EXIT_STATUS!
)
echo %INFO% %BLCK_LBL%: Fetched metadata to "%META_FILE%".

:SKIP_META_FETCH

:: --------------------------------------------------------
:: Extract asset URL (prefer jq, fallback Findstr)
:: --------------------------------------------------------
if not defined JQ (
  where jq.exe >nul 2>&1 && set "JQ=jq.exe"
)
if not defined JQ if exist "%CACHE%\JQ\jq.exe" set "JQ=%CACHE%\JQ\jq.exe"
if not defined JQ (
  echo %INFO% %BLCK_LBL%: JQ is not available. Will use FINDSTR.
  goto :FINDSTR_ASSET_URL
)

:: --- Use JQ, if available ---

echo %INFO% %BLCK_LBL%: Parsing %COMMON_NAME% JSON metadata with JQ.

rem Escape period in ASSET_URL_SUFFIX with \\ for JQ command line processing.
rem Note: could not escape JQ PATTERN for use in FOR LOOP.

set "_ASSET_URL_SUFFIX=%ASSET_URL_SUFFIX:.=\\.%$"
set "PATTERN=.assets[] | select(.browser_download_url | test(""%_ASSET_URL_SUFFIX%"")) | .browser_download_url"

rem If JQ is set, its validity is intentionally not checked to allow potential failure of the next command.
rem This omission is probably not generally good for production, and is left unguarded solely to allow for
rem FINDSTR fallback.

call "%JQ%"  -r "%PATTERN%" "%META_FILE%" >"%TEMP%\ASSET_URL.txt"
set "EXIT_STATUS=!ERRORLEVEL!"
if not %EXIT_STATUS% equ 0 (
  echo %WARN% %BLCK_LBL%: JQ asset URL extraction failed. ERROR: %EXIT_STATUS%. Will try FINDSTR.
  set "ASSET_URL="
  goto :FINDSTR_ASSET_URL
)

for /f "usebackq delims=" %%A in ("%TEMP%\ASSET_URL.txt") do set "ASSET_URL=%%A"
del /Q "%TEMP%\ASSET_URL.txt"
if defined ASSET_URL goto :SKIP_FINDSTR_ASSET_URL
:FINDSTR_ASSET_URL
:: --- Findstr fallback ---

echo %INFO% %BLCK_LBL%: Parsing %COMMON_NAME% JSON metadata with FINDSTR
rem Escape period in ASSET_URL_SUFFIX with \ for FINSTR command line processing.

set "_ASSET_URL_SUFFIX=%ASSET_URL_SUFFIX:.=\.%"
set "PATTERN=^[ ]*\"browser_download_url\":[ ]*\"https://github.com/%REPO_NAME%/releases/download/.*%_ASSET_URL_SUFFIX%\""
for /f "usebackq tokens=2 delims=, " %%A in (`findstr /R /I /C:"%PATTERN%" "%META_FILE%"`) do (
  set "ASSET_URL=%%~A"
)
REM ERROR HANDLING
REM   Somehow ERRORLEVEL is set to 1 even on success. Removed this check completely.
REM   Will rely on the ultimate check of ASSET_URL next.

:SKIP_FINDSTR_ASSET_URL

set "_ASSET_URL_SUFFIX="

if not defined ASSET_URL (
  echo %ERROR% %BLCK_LBL%: Could not locate ASSET URL.
  set "EXIT_STATUS=1"
) else (
  echo %INFO% %BLCK_LBL%: Using asset URL !ASSET_URL!.
  set  "EXIT_STATUS=0"
)

exit /b %EXIT_STATUS%
:: ============================================================================
:: ============================================================================ RETRIEVE_ASSET_URL END
