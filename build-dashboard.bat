@echo off
setlocal enabledelayedexpansion

set "ROOT_DIR=%~dp0"
set "DASHBOARD_DIR=%ROOT_DIR%frontend\apps\joppe_dashboard"

echo ========================================================
echo [Joppe Dashboard] Flutter Web Build
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
    where flutter >nul 2>&1
    if !ERRORLEVEL! equ 0 set "FLUTTER_CMD=flutter"
)

if not defined FLUTTER_CMD (
    echo [ERROR] Flutter SDK not found on PATH or standard installation path.
    echo Please install Flutter and add flutter\bin to your system PATH.
    exit /b 1
)

rem 3. Parse target environment (dev or prod, default: prod)
set "TARGET_ENV=%~1"
set "EXTRA_ARGS="

if /i "%TARGET_ENV%"=="dev" (
    set "ENV_MODE=dev"
    set "API_BASE_URL=http://localhost:8080"
    set "ENV_CONFIG_FILE=%DASHBOARD_DIR%\env.dev.json"
    shift
) else if /i "%TARGET_ENV%"=="development" (
    set "ENV_MODE=dev"
    set "API_BASE_URL=http://localhost:8080"
    set "ENV_CONFIG_FILE=%DASHBOARD_DIR%\env.dev.json"
    shift
) else if /i "%TARGET_ENV%"=="local" (
    set "ENV_MODE=dev"
    set "API_BASE_URL=http://localhost:8080"
    set "ENV_CONFIG_FILE=%DASHBOARD_DIR%\env.dev.json"
    shift
) else if /i "%TARGET_ENV%"=="prod" (
    set "ENV_MODE=prod"
    set "API_BASE_URL=https://joppe.penguinlab.org"
    set "ENV_CONFIG_FILE=%DASHBOARD_DIR%\env.prod.json"
    shift
) else if /i "%TARGET_ENV%"=="production" (
    set "ENV_MODE=prod"
    set "API_BASE_URL=https://joppe.penguinlab.org"
    set "ENV_CONFIG_FILE=%DASHBOARD_DIR%\env.prod.json"
    shift
) else (
    rem If first argument is not dev/prod, default to prod and keep all arguments
    set "ENV_MODE=prod"
    set "API_BASE_URL=https://joppe.penguinlab.org"
    set "ENV_CONFIG_FILE=%DASHBOARD_DIR%\env.prod.json"
)

rem Collect remaining arguments
:COLLECT_ARGS
if not "%~1"=="" (
    set "EXTRA_ARGS=!EXTRA_ARGS! %1"
    shift
    goto :COLLECT_ARGS
)

echo --------------------------------------------------------
echo Environment Mode   : [%ENV_MODE%]
echo API Base URL       : %API_BASE_URL%
echo Config File        : %ENV_CONFIG_FILE%
if defined EXTRA_ARGS (
    echo Additional Flags   : %EXTRA_ARGS%
)
echo --------------------------------------------------------

rem 4. Verify config file exists
if not exist "%ENV_CONFIG_FILE%" (
    echo [WARNING] Config file %ENV_CONFIG_FILE% not found.
    echo Building with explicit --dart-define=API_BASE_URL=%API_BASE_URL%
    set "DEFINE_FLAG=--dart-define=API_BASE_URL=%API_BASE_URL%"
) else (
    set "DEFINE_FLAG=--dart-define-from-file="%ENV_CONFIG_FILE%" --dart-define=API_BASE_URL=%API_BASE_URL%"
)

rem 5. Execute Flutter Web Build
echo Compiling Flutter Web for %ENV_MODE%...
cd /d "%DASHBOARD_DIR%"
call "%FLUTTER_CMD%" build web --release !DEFINE_FLAG! !EXTRA_ARGS!
set "BUILD_STATUS=%ERRORLEVEL%"
cd /d "%ROOT_DIR%"

if %BUILD_STATUS% neq 0 (
    echo ========================================================
    echo [ERROR] Dashboard build failed with exit code %BUILD_STATUS%
    echo ========================================================
    exit /b %BUILD_STATUS%
)

echo ========================================================
echo [SUCCESS] Joppe Dashboard [%ENV_MODE%] built successfully!
echo Output directory:
echo   %DASHBOARD_DIR%\build\web
echo ========================================================

exit /b 0
