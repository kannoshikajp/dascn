@echo off
echo Building Android for POD (Prod) environment...
powershell.exe -ExecutionPolicy Bypass -File "%~dp0build_android.ps1" -Environment pod -BuildType appbundle
pause
