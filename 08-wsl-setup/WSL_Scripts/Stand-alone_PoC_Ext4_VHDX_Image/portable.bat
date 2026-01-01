@echo off
setlocal EnableDelayedExpansion

set "VHD_PATH=%~dp0portable.ext4.vhdx"
set "MOUNT_NAME=portable"

:: --- STEP 1: ATTACH VHDX IN DISKPART ---
echo [INFO] Attaching VHDX via Diskpart...
set "DP_SCRIPT=%TEMP%\attach_vhd.txt"
(
    echo select vdisk file="%VHD_PATH%"
    echo attach vdisk
) > "%DP_SCRIPT%"

diskpart /s "%DP_SCRIPT%" >nul
del "%DP_SCRIPT%"

:: --- STEP 2: FIND PHYSICAL DRIVE NUMBER ---
:: We use PowerShell to find which Disk Number Windows assigned to this specific VHDX file.
echo [INFO] Identifying Physical Drive ID...
for /f "usebackq tokens=*" %%A in (`powershell -NoProfile -Command "Get-DiskImage -ImagePath '%VHD_PATH%' | Get-Disk | Select-Object -ExpandProperty Number"`) do (
    set "DISK_NUM=%%A"
)

if "%DISK_NUM%"=="" (
    echo [FATAL] Could not identify Disk ID. Is the VHDX attached?
    goto :EOF
)

echo [INFO] VHDX is attached as Disk %DISK_NUM%.

:: --- STEP 3: SET DISK OFFLINE (REQUIRED FOR WSL) ---
:: WSL cannot touch the disk if Windows is reading it. We must take it Offline.
echo [INFO] Setting Disk %DISK_NUM% Offline...
set "DP_OFFLINE=%TEMP%\offline_disk.txt"
(
    echo select disk %DISK_NUM%
    echo offline disk
) > "%DP_OFFLINE%"

diskpart /s "%DP_OFFLINE%" >nul
del "%DP_OFFLINE%"

:: --- STEP 4: MOUNT TO WSL ---
echo [INFO] Mounting \\.\PHYSICALDRIVE%DISK_NUM% to WSL...

:: Note: We do NOT use '--vhd' here because we are pointing to a PhysicalDrive, not a file.
wsl --mount \\.\PHYSICALDRIVE%DISK_NUM% --name "%MOUNT_NAME%"

echo [SUCCESS] Mounted at /mnt/wsl/%MOUNT_NAME%
pause
