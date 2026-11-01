@echo off
setlocal
set "ROOT_DIR=%~dp0"
call "%ROOT_DIR%build-dashboard.bat" dev %*
exit /b %ERRORLEVEL%
