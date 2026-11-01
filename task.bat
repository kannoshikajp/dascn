@echo off
setlocal enabledelayedexpansion

set "ROOT_DIR=%~dp0"
set "TASK_EXE=%ROOT_DIR%.tools\task.exe"

rem 1. Check tool via check-tool.bat if missing
if not exist "%TASK_EXE%" (
    call "%ROOT_DIR%check-tool.bat" "%~f0" %*
    exit /b !ERRORLEVEL!
)

rem 2. If arguments passed, execute task directly
if not "%~1"=="" (
    "%TASK_EXE%" --taskfile "%ROOT_DIR%Taskfile.yml" %*
    exit /b !ERRORLEVEL!
)

rem 3. If no arguments (double-clicked without opening cmd), show interactive menu
:MENU
cls
echo ========================================================
echo             JOPPE TECH STORE - TASK MANAGER
echo ========================================================
echo.
echo  --- Development ---
echo   1. Backend (Spring Boot Dev)           [backend:dev]
echo   2. Dashboard Web (Chrome port 8888)    [dashboard:dev]
echo   3. Storefront App Web (Chrome port 3000)[app:dev:web]
echo   4. Storefront App Windows Desktop      [app:dev:windows]
echo.
echo  --- Build & Packaging ---
echo   5. Build Backend JAR                   [backend:build]
echo   6. Build Dashboard Web (Production)    [dashboard:build:prod]
echo   7. Build Dashboard Web (Development)   [dashboard:build:dev]
echo   8. Build Release APKs (Split per ABI)  [apk:build:release]
echo   9. Build Debug APKs (Split per ABI)    [apk:build:dev]
echo.
echo  --- Testing & Quality ---
echo  10. Run All Test Suites (Full System)   [test:all]
echo  11. Run Backend JUnit Tests             [backend:test]
echo  12. Run Dashboard Widget Tests          [dashboard:test]
echo  13. Run Storefront App Tests            [app:test]
echo.
echo  --- Infrastructure & Tools ---
echo  14. Start MailHog (Docker)              [mailhog:start]
echo  15. Stop MailHog (Docker)               [mailhog:stop]
echo  16. List All Available Tasks            [--list]
echo.
echo   0. Exit
echo ========================================================
set /p "CHOICE=Enter selection [0-16] (or type task name): "

if "%CHOICE%"=="0" exit /b 0
if "%CHOICE%"=="" goto :MENU
set "SELECTED_TASK="
if "%CHOICE%"=="1" set "SELECTED_TASK=backend:dev"
if "%CHOICE%"=="2" set "SELECTED_TASK=dashboard:dev"
if "%CHOICE%"=="3" set "SELECTED_TASK=app:dev:web"
if "%CHOICE%"=="4" set "SELECTED_TASK=app:dev:windows"
if "%CHOICE%"=="5" set "SELECTED_TASK=backend:build"
if "%CHOICE%"=="6" set "SELECTED_TASK=dashboard:build:prod"
if "%CHOICE%"=="7" set "SELECTED_TASK=dashboard:build:dev"
if "%CHOICE%"=="8" set "SELECTED_TASK=apk:build:release"
if "%CHOICE%"=="9" set "SELECTED_TASK=apk:build:dev"
if "%CHOICE%"=="10" set "SELECTED_TASK=test:all"
if "%CHOICE%"=="11" set "SELECTED_TASK=backend:test"
if "%CHOICE%"=="12" set "SELECTED_TASK=dashboard:test"
if "%CHOICE%"=="13" set "SELECTED_TASK=app:test"
if "%CHOICE%"=="14" set "SELECTED_TASK=mailhog:start"
if "%CHOICE%"=="15" set "SELECTED_TASK=mailhog:stop"
if "%CHOICE%"=="16" set "SELECTED_TASK=--list"

if not defined SELECTED_TASK set "SELECTED_TASK=%CHOICE%"

echo.
echo ========================================================
echo Executing: task %SELECTED_TASK%
echo ========================================================
"%TASK_EXE%" --taskfile "%ROOT_DIR%Taskfile.yml" %SELECTED_TASK%
echo.
echo ========================================================
echo Task finished with exit code %ERRORLEVEL%.
echo ========================================================
pause
goto :MENU
