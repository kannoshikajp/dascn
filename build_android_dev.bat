@echo off
echo Building Android for DEV environment...
powershell.exe -ExecutionPolicy Bypass -File "%~dp0build_android.ps1" -Environment dev -BuildType apk
pause
