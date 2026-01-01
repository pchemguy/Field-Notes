@echo off
setlocal EnableDelayedExpansion


set "WSL_UTF8=1"
set "PORTABLE=G:\dev\WSL\UbuntuLTS\portable.ext4.vhdx"

if exist "%PORTABLE%" (
    echo [FATAL] File "%PORTABLE%" exists. Aborting...
    exit /b 1
)

:: Create a temporary script for Diskpart
set "DP_SCRIPT=%TEMP%\create_vhd.txt"
echo create vdisk file="%PORTABLE%" maximum=51200 type=expandable > "%DP_SCRIPT%"

echo [INFO] Creating 50GB VHDX via Diskpart...
diskpart /s "%DP_SCRIPT%"

:: Clean up temp file
del "%DP_SCRIPT%"

echo [INFO] Done.