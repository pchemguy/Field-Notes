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

set "UPDATE_CACHE="
set "NO_TOP_BAR="
set "NO_BOTTOM_BAR=1"
set "ESCAPE_COLORS_SILENT="
call "GitHubRelease.bat" & set "EXIT_STATUS=%ERRORLEVEL%"

endlocal & (set "JQ=%JQ%") & (set "CACHE=%CACHE%")

setlocal

rem Fail Test BAD REPO NAME - Direct download

set "COMMON_NAME=FAIL_DIRECT_BAD_REPO"
set "REPO_NAME=bad/repo"
REM - Direct download
set "ASSET_URL_SUFFIX="
set "RELEASE_URL_SUFFIX=micromamba-win-64.exe"
REM - File extension in URL.
set "DOWNLOAD_EXT="
set "CANONICAL_NAME=micromamba.exe"
rem Use old file name from URL
set "SPECIFIC_NAME="

set "UPDATE_CACHE=1"
set "NO_TOP_BAR=1"
set "NO_BOTTOM_BAR=1"
set "ESCAPE_COLORS_SILENT=1"
call "GitHubRelease.bat" & set "EXIT_STATUS=%ERRORLEVEL%"

setlocal

rem Fail Test BAD REPO NAME - Indirect download

set "COMMON_NAME=FAIL_INDIRECT_BAD_REPO"
set "REPO_NAME=bad/repo"
REM - Direct download
set "ASSET_URL_SUFFIX=vc-x64.exe"
set "RELEASE_URL_SUFFIX=libjpeg-turbo-vc-x64.exe"
REM - File extension in URL.
set "DOWNLOAD_EXT="
set "CANONICAL_NAME="
rem Use old file name from URL
set "SPECIFIC_NAME="

set "UPDATE_CACHE=1"
set "NO_TOP_BAR=1"
set "NO_BOTTOM_BAR=1"
set "ESCAPE_COLORS_SILENT=1"
call "GitHubRelease.bat" & set "EXIT_STATUS=%ERRORLEVEL%"

endlocal

setlocal

rem Test Bad JQ - Fail JQ, Fallback to FINSTR

set "COMMON_NAME=FALLBACK_FINDSTR_FAIL_JQ"
set "REPO_NAME=libjpeg-turbo/libjpeg-turbo"
REM - Direct download
set "ASSET_URL_SUFFIX=vc-x64.exe"
set "RELEASE_URL_SUFFIX=libjpeg-turbo-vc-x64.exe"
REM - File extension in URL.
set "DOWNLOAD_EXT="
set "CANONICAL_NAME="
rem Use old file name from URL
set "SPECIFIC_NAME="

set "JQ=_"
set "UPDATE_CACHE=1"
set "NO_TOP_BAR=1"
set "NO_BOTTOM_BAR=1"
set "ESCAPE_COLORS_SILENT=1"
call "GitHubRelease.bat" & set "EXIT_STATUS=%ERRORLEVEL%"

endlocal

setlocal

rem Test Fake ZIP

set "COMMON_NAME=FAIL_FAKE_ZIP"
set "REPO_NAME=jqlang/jq"
REM - Direct download
set "ASSET_URL_SUFFIX="
set "RELEASE_URL_SUFFIX=jq-win64.exe"
REM - File extension in URL.
set "DOWNLOAD_EXT=.zip"
set "CANONICAL_NAME=jq.exe"
rem Use old file name from URL
set "SPECIFIC_NAME="

set "UPDATE_CACHE=1"
set "NO_TOP_BAR=1"
set "NO_BOTTOM_BAR=1"
set "ESCAPE_COLORS_SILENT=1"
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

set "UPDATE_CACHE="
set "NO_TOP_BAR=1"
set "NO_BOTTOM_BAR="
set "ESCAPE_COLORS_SILENT=1"
call "GitHubRelease.bat" & set "EXIT_STATUS=%ERRORLEVEL%"

endlocal


rem ############################################################################
rem A separate failed test.

setlocal

rem Fail Test Read Only Cache

set "COMMON_NAME=FAIL_CACHE_RO"
set "REPO_NAME=mamba-org/micromamba-releases"
REM - Direct download
set "ASSET_URL_SUFFIX="
set "RELEASE_URL_SUFFIX=micromamba-win-64.exe"
REM - File extension in URL.
set "DOWNLOAD_EXT="
set "CANONICAL_NAME=micromamba.exe"
rem Use old file name from URL
set "SPECIFIC_NAME="

set "CACHE=%ALLUSERSPROFILE%"
set "UPDATE_CACHE=1"
set "NO_TOP_BAR="
set "NO_BOTTOM_BAR="
set "ESCAPE_COLORS_SILENT=1"
call "GitHubRelease.bat" & set "EXIT_STATUS=%ERRORLEVEL%"

endlocal
