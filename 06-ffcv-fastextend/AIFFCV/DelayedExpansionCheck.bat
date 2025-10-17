@echo off

echo:
echo --- Checking cmd.exe delayed expansion availability ---
echo:


if "%ComSpec%"=="!ComSpec!" (
  echo:
  echo --------------------------
  echo CHECK PASSED
  echo Delayed Expansion enabled!
  echo --------------------------
  echo:
  exit /b 0
)


echo:
echo ----------------------------------------------------------
echo CHECK FAILED
echo cmd.exe Delayed Expansion is not active. Set the following
echo setting (either variant should do), start a new shell, run
echo this script again, and make sure the check passes.
echo Otherwise, try rebooting your computer.
echo ----------------------------------------------------------
echo: 
echo Delayed expansion activation settings. 
echo: 
echo ---------------------------------------------------------
echo [HKEY_CURRENT_USER\Software\Microsoft\Command Processor]
echo "DelayedExpansion"=dword:00000001
echo "EnableExtensions"=dword:00000001
echo:
echo --- OR ---
echo:
echo [HKEY_LOCAL_MACHINE\Software\Microsoft\Command Processor]
echo "DelayedExpansion"=dword:00000001
echo "EnableExtensions"=dword:00000001
echo ---------------------------------------------------------
echo:
