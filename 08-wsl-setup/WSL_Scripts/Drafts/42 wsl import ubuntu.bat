@echo off
setlocal EnableDelayedExpansion


REM ===================================== WSL =========================================
REM https://learn.microsoft.com/en-us/windows/wsl/install
REM https://learn.microsoft.com/en-us/windows/wsl/setup/environment
REM https://cloud-images.ubuntu.com/wsl/releases/24.04/current/
REM
REM wsl.exe --list --verbose
REM wsl.exe --list --online

REM Ubuntu 24.04 LTS - https://releases.ubuntu.com/noble/ 
REM dism.exe /online /enable-feature /featurename:VirtualMachinePlatform /all /norestart
REM "%~dp0../RunTime/WSL2/wsl.2.6.3.0.x64.msi" /quiet /norestart
REM wsl --install --from-file ../RunTime/WSL2/ubuntu-24.04.3-wsl-amd64.wsl


set "WSL_UTF8=1"

:: ====================================================================================
:: GUARD 1: Verify WSL Engine Installation (MSI/Strict Mode)
:: ====================================================================================

set "WSL_ROOT=%ProgramFiles%\WSL"
set "WSL_INITIALIZED=1"

:: Check for the directory
if not exist "%WSL_ROOT%" (
    echo [Check Failed] "%WSL_ROOT%" is not found.
    set "WSL_INITIALIZED="
)

:: Check for the main executable

if defined WSL_INITIALIZED if not exist "%WSL_ROOT%\wsl.exe" (
    echo [Check Failed] "%WSL_ROOT%\wsl.exe" is missing.
    set "WSL_INITIALIZED="
)

:: Check for the service

if defined WSL_INITIALIZED if not exist "%WSL_ROOT%\wslservice.exe" (
    echo [Check Failed] "%WSL_ROOT%\wslservice.exe" is missing.
    set "WSL_INITIALIZED="
)

:: Check for the System Distro (WSLg/system.vhd)
:: Note: This file is standard in the MSI package but technically optional for headless servers.
:: We keep your check as it ensures a "complete" install.

if defined WSL_INITIALIZED if not exist "%WSL_ROOT%\system.vhd" (
    echo [Check Failed] "%WSL_ROOT%\system.vhd" is missing.
    set "WSL_INITIALIZED="
)

if not defined WSL_INITIALIZED (
    echo [FATAL] WSL components are missing or incomplete. 
    echo Please run the installer script again.
    exit /b 1
)

:: ====================================================================================
:: GUARD 2: Check for Pending Reboot / Status Errors
:: ====================================================================================

echo Checking WSL Kernel status...
set "STATUS_OK=1"

:: We loop through output looking for known failure strings.

for /f "usebackq delims=" %%S in (`wsl --status`) do (
    set "LINE=%%S"
    
    :: Logic: Substitute "not supported" with nothing. If string changes, the error was found.
    if not "!LINE:WSL2 is not supported=!"=="!LINE!" (
        echo [FATAL] wsl --status reports: "WSL2 is not supported".
        set "STATUS_OK=0"
    )
)

if "%STATUS_OK%"=="0" (
    echo.
    echo A mandatory reboot is likely pending.
    echo Please REBOOT the machine and try again.
    exit /b 1
)

:: ====================================================================================
:: SETUP: Import Configuration
:: ====================================================================================

set "ENV_NAME=UbuntuLTS"
set "PREFIX=G:\dev\WSL\UbuntuLTS"
set "ROOTFS=%~dp0..\RunTime\WSL\ubuntu-noble-wsl-amd64-24.04lts.rootfs.tar.gz"

:: ====================================================================================
:: GUARD 3: Check if ENV_NAME is already in use
:: ====================================================================================

:: Improved method: Pipe directly to findstr. 
:: /x matches exact line, /c specifies string. 
:: This avoids iterating line-by-line which can fail with UTF-16 encoding.

wsl --list --quiet | findstr /x /c:"%ENV_NAME%" >nul
if %ERRORLEVEL% equ 0 (
    echo [ERROR] The distro "%ENV_NAME%" is already registered.
    exit /b 1
)

:: ====================================================================================
:: EXECUTION: Prepare and Import
:: ====================================================================================

:: --- Check if PREFIX folder exists (Create if missing) ---

if not exist "%PREFIX%" (
    echo Creating directory: "%PREFIX%"
    md "%PREFIX%"
    if !ERRORLEVEL! neq 0 (
        echo [ERROR] Failed to create directory "%PREFIX%". Check permissions.
        exit /b 1
    )
)

:: --- Check if ROOTFS file exists ---

if not exist "%ROOTFS%" (
    echo [ERROR] Source file not found: "%ROOTFS%"
    exit /b 1
)

:: --- Check ROOTFS suffix ---

if /i not "%ROOTFS:~-14%"==".rootfs.tar.gz" (
    echo [ERROR] File extension mismatch. Expected: .rootfs.tar.gz
    echo Found: "%ROOTFS%"
    exit /b 1
)

echo.
echo [INFO] Importing %ENV_NAME%...
echo   Source: %ROOTFS%
echo   Dest:   %PREFIX%
echo.

wsl --import "%ENV_NAME%" "%PREFIX%" "%ROOTFS%" --version 2

if not "%ERRORLEVEL%"=="0" (
    echo [FAIL] Import encountered an error.
    exit /b 1
)

if not exist "%PREFIX%\ext4.vhdx" (
    echo [FAIL] New image file "%PREFIX%\ext4.vhdx" not found.
    exit /b 1
)
    
echo [SUCCESS] Import complete. The new image file:
echo           "%PREFIX%\ext4.vhdx"
