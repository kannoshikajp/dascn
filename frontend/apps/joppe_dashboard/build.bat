@echo off
setlocal
set "DIR=%~dp0"
call "%DIR%..\..\..\build-dashboard.bat" %*
exit /b %ERRORLEVEL%
