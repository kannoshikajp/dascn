@echo off
echo Building Spring Boot Backend (JAR)...
powershell.exe -ExecutionPolicy Bypass -File "%~dp0build_backend.ps1"
pause
