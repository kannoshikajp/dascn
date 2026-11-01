@echo off
set "ROOT_DIR=%~dp0"
if not exist "%ROOT_DIR%.tools\task.exe" (
    call "%ROOT_DIR%check-tool.bat" "%~f0" %*
    exit /b %ERRORLEVEL%
)

echo ========================================================
echo Starting Backend in Development Mode [backend:dev]...
echo ========================================================
"%ROOT_DIR%.tools\task.exe" --taskfile "%ROOT_DIR%Taskfile.yml" backend:dev %*
set "STATUS=%ERRORLEVEL%"
if %STATUS% neq 0 pause
exit /b %STATUS%
