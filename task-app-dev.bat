@echo off
set "ROOT_DIR=%~dp0"
if not exist "%ROOT_DIR%.tools\task.exe" (
    call "%ROOT_DIR%check-tool.bat" "%~f0" %*
    exit /b %ERRORLEVEL%
)

echo ========================================================
echo Starting Joppe Customer Storefront Web [app:dev:web]...
echo ========================================================
"%ROOT_DIR%.tools\task.exe" --taskfile "%ROOT_DIR%Taskfile.yml" app:dev:web %*
set "STATUS=%ERRORLEVEL%"
if %STATUS% neq 0 pause
exit /b %STATUS%
