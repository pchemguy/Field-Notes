@echo off

set "VHD_PATH=%~dp0portable.ext4.vhdx"
set "SCRIPT=%TEMP%\mount_vhd.txt"

(
    echo select vdisk file="%VHD_PATH%"
    echo attach vdisk
) > "%SCRIPT%"

diskpart /s "%SCRIPT%"
del "%SCRIPT%"
