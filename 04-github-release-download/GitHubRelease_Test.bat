@echo off

rem This is a test file for GitHubRelease.bat

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

call "GitHubRelease.bat" & set "EXIT_STATUS=%ERRORLEVEL%"

endlocal & exit /b %EXIT_STATUS%
