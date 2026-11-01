@echo off
set "ROOT_DIR=%~dp0"
if not exist "%ROOT_DIR%.tools\task.exe" (
    call "%ROOT_DIR%check-tool.bat" "%~f0" %*
    exit /b %ERRORLEVEL%
)

echo ========================================================
echo Running Full Test Suite [test:all]...
echo ========================================================
"%ROOT_DIR%.tools\task.exe" --taskfile "%ROOT_DIR%Taskfile.yml" test:all %*
set "STATUS=%ERRORLEVEL%"
echo.
echo ========================================================
echo Test suite finished with exit code %STATUS%.
echo ========================================================
pause
exit /b %STATUS%
