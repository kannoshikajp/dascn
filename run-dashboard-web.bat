@echo off
setlocal enabledelayedexpansion

set "ROOT_DIR=%~dp0"
set "DASHBOARD_DIR=%ROOT_DIR%frontend\apps\joppe_dashboard"

echo ========================================================
echo [Joppe Dashboard] Starting Flutter Web Control Center...
echo ========================================================

rem 1. Check dashboard directory
if not exist "%DASHBOARD_DIR%\pubspec.yaml" (
    echo [ERROR] Dashboard directory not found at:
    echo   %DASHBOARD_DIR%
    exit /b 1
)

rem 2. Verify Flutter SDK availability
set "FLUTTER_CMD="
for /f "delims=" %%I in ('where flutter.bat 2^>nul') do (
    if not defined FLUTTER_CMD set "FLUTTER_CMD=%%I"
)
if not defined FLUTTER_CMD if exist "D:\DevTools\SDKs\flutter\bin\flutter.bat" (
    set "FLUTTER_CMD=D:\DevTools\SDKs\flutter\bin\flutter.bat"
    set "PATH=D:\DevTools\SDKs\flutter\bin;!PATH!"
)

if not defined FLUTTER_CMD (
    echo [ERROR] Flutter SDK not found in PATH or standard installation path.
    echo Please install Flutter and add flutter\bin to your system PATH.
    exit /b 1
)

for %%I in ("%FLUTTER_CMD%\..\..") do set "FLUTTER_ROOT=%%~fi"

rem 3. Load environment variables if available (.env / .env.local)
set "API_BASE_URL=http://localhost:8080"
set "WEB_PORT=3000"

set "ENV_FILE="
if exist "%ROOT_DIR%.env.local" set "ENV_FILE=%ROOT_DIR%.env.local"
if not defined ENV_FILE if exist "%ROOT_DIR%.env" set "ENV_FILE=%ROOT_DIR%.env"
if not defined ENV_FILE if exist "%ROOT_DIR%backend\.env" set "ENV_FILE=%ROOT_DIR%backend\.env"

if defined ENV_FILE (
    echo Loading configuration from: %ENV_FILE%
    for /f "usebackq eol=# tokens=1* delims==" %%A in ("%ENV_FILE%") do (
        set "K=%%A"
        set "V=%%B"
        if defined K if defined V (
            for /f "tokens=* delims= " %%X in ("!K!") do set "K=%%X"
            if /i "!K!"=="API_BASE_URL" set "API_BASE_URL=!V!"
            if /i "!K!"=="DASHBOARD_PORT" set "WEB_PORT=!V!"
            if /i "!K!"=="WEB_PORT" set "WEB_PORT=!V!"
        )
    )
)

echo Backend API Target : %API_BASE_URL%
echo Web Dev Port       : %WEB_PORT%

rem 4. Check for user-supplied flags in %*
set "USER_SPECIFIED_DEVICE=0"
set "USER_SPECIFIED_PORT=0"
set "USER_SPECIFIED_API=0"

for %%A in (%*) do (
    set "ARG=%%~A"
    if /i "!ARG!"=="-d" set "USER_SPECIFIED_DEVICE=1"
    if /i "!ARG!"=="--device-id" set "USER_SPECIFIED_DEVICE=1"
    if "!ARG:~0,11!"=="--web-port=" set "USER_SPECIFIED_PORT=1"
    if "!ARG:~0,27!"=="--dart-define=API_BASE_URL=" set "USER_SPECIFIED_API=1"
)

rem 5. Auto-detect browser device (chrome, edge, web-server)
set "DEVICE_ARG="
if "!USER_SPECIFIED_DEVICE!"=="0" (
    set "DETECTED_DEVICE="
    if exist "%ProgramFiles%\Google\Chrome\Application\chrome.exe" set "DETECTED_DEVICE=chrome"
    if not defined DETECTED_DEVICE if exist "%ProgramFiles(x86)%\Google\Chrome\Application\chrome.exe" set "DETECTED_DEVICE=chrome"
    if not defined DETECTED_DEVICE if exist "%LocalAppData%\Google\Chrome\Application\chrome.exe" set "DETECTED_DEVICE=chrome"
    if not defined DETECTED_DEVICE if exist "%ProgramFiles(x86)%\Microsoft\Edge\Application\msedge.exe" set "DETECTED_DEVICE=edge"
    if not defined DETECTED_DEVICE if exist "%ProgramFiles%\Microsoft\Edge\Application\msedge.exe" set "DETECTED_DEVICE=edge"
    if not defined DETECTED_DEVICE set "DETECTED_DEVICE=web-server"

    echo Detected Web Device: !DETECTED_DEVICE!
    set "DEVICE_ARG=-d !DETECTED_DEVICE!"
)

rem 6. Build optional arguments
set "PORT_ARG="
if "!USER_SPECIFIED_PORT!"=="0" (
    set "PORT_ARG=--web-port=%WEB_PORT%"
)

set "API_ARG="
if "!USER_SPECIFIED_API!"=="0" (
    set "API_ARG=--dart-define=API_BASE_URL=%API_BASE_URL%"
)

rem 7. Execute Flutter Web
echo ========================================================
echo Launching joppe_dashboard in web mode...
echo ========================================================

cd /d "%DASHBOARD_DIR%"
call "%FLUTTER_CMD%" run !DEVICE_ARG! !PORT_ARG! !API_ARG! %*
set "RUN_STATUS=%ERRORLEVEL%"
cd /d "%ROOT_DIR%"

exit /b %RUN_STATUS%
