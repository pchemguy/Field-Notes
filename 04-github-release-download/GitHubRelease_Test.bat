@echo off

rem This is a test file for GitHubRelease.bat

setlocal

rem Libjpeg-Turbo

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

endlocal


setlocal

rem Micromamba

set "COMMON_NAME=Micromamba"
set "REPO_NAME=mamba-org/micromamba-releases"
REM - Direct download
set "ASSET_URL_SUFFIX="
set "RELEASE_URL_SUFFIX=micromamba-win-64.exe"
REM - File extension in URL.
set "DOWNLOAD_EXT="
set "CANONICAL_NAME=micromamba.exe"
rem Use old file name from URL
set "SPECIFIC_NAME="

call "GitHubRelease.bat" & set "EXIT_STATUS=%ERRORLEVEL%"

endlocal & exit /b %EXIT_STATUS%

