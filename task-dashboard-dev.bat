@echo off
set "ROOT_DIR=%~dp0"
if not exist "%ROOT_DIR%.tools\task.exe" (
    call "%ROOT_DIR%check-tool.bat" "%~f0" %*
    exit /b %ERRORLEVEL%
)

echo ========================================================
echo Starting Joppe Dashboard in Development Mode [dashboard:dev]...
echo ========================================================
"%ROOT_DIR%.tools\task.exe" --taskfile "%ROOT_DIR%Taskfile.yml" dashboard:dev %*
set "STATUS=%ERRORLEVEL%"
if %STATUS% neq 0 pause
exit /b %STATUS%
