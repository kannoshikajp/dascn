@echo off
set "ROOT_DIR=%~dp0"
if not exist "%ROOT_DIR%.tools\task.exe" (
    call "%ROOT_DIR%check-tool.bat" "%~f0" %*
    exit /b %ERRORLEVEL%
)

echo ========================================================
echo Building Joppe Dashboard Web (Production) [dashboard:build:prod]...
echo ========================================================
"%ROOT_DIR%.tools\task.exe" --taskfile "%ROOT_DIR%Taskfile.yml" dashboard:build:prod %*
set "STATUS=%ERRORLEVEL%"
echo.
echo ========================================================
echo Dashboard build finished with exit code %STATUS%.
echo ========================================================
pause
exit /b %STATUS%
