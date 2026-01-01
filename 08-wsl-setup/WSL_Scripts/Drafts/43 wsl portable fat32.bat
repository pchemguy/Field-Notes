@echo off
setlocal EnableDelayedExpansion


set "WSL_UTF8=1"
set "PORTABLE=G:\dev\WSL\UbuntuLTS\portable.fat32.vhdx"
set "DP_SCRIPT=%TEMP%\create_fat32.txt"

:: Create the temporary Diskpart script
(
    echo create vdisk file="%PORTABLE%" maximum=32768 type=expandable
    echo attach vdisk
    REM Initialize disk as MBR so we can create a partition
    echo convert mbr
    echo create partition primary
    REM Format as exFAT (Use fs=fat32 if you prefer standard FAT32)
    echo format fs=fat32 quick label="Portable"
    echo detach vdisk
) > "%DP_SCRIPT%"

echo [INFO] Creating and formatting 32GB FAT32 VHDX...
diskpart /s "%DP_SCRIPT%"

:: Clean up
del "%DP_SCRIPT%"
echo [SUCCESS] Done.

