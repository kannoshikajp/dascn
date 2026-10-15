@echo off
setlocal enabledelayedexpansion

set "ROOT_DIR=%~dp0"
set "FRONTEND_DIR=%ROOT_DIR%frontend"
set "TOOLS_DIR=%ROOT_DIR%.tools"
set "JDK_DIR=%TOOLS_DIR%\jdk-21"

echo ========================================================
echo [1/3] Checking Flutter and Java environment...
echo ========================================================

rem 1. Set Java environment
if exist "%JDK_DIR%\bin\java.exe" (
    set "JAVA_HOME=%JDK_DIR%"
    set "PATH=%JDK_DIR%\bin;!PATH!"
) else if defined JAVA_HOME (
    if exist "%JAVA_HOME%\bin\java.exe" (
        set "PATH=%JAVA_HOME%\bin;!PATH!"
    )
)

where flutter.bat >nul 2>&1
if %ERRORLEVEL% neq 0 (
    where flutter >nul 2>&1
    if %ERRORLEVEL% neq 0 (
        echo [ERROR] Flutter SDK not found on PATH.
        exit /b 1
    )
)

echo Flutter detected:
call flutter --version
echo.

set "TARGET=%~1"
if "%TARGET%"=="" set "TARGET=all"

echo ========================================================
echo [2/3] Building RELEASE APKs with split-per-abi...
echo Target: %TARGET%
echo ========================================================

if "%TARGET%"=="all" (
    call :BUILD_APP "joppe_app"
    if !ERRORLEVEL! neq 0 exit /b !ERRORLEVEL!
    call :BUILD_APP "joppe_dashboard"
    if !ERRORLEVEL! neq 0 exit /b !ERRORLEVEL!
) else (
    call :BUILD_APP "%TARGET%"
    if !ERRORLEVEL! neq 0 exit /b !ERRORLEVEL!
)

echo ========================================================
echo [3/3] RELEASE APK Build SUCCESS!
echo ========================================================
goto :eof

:BUILD_APP
set "APP_NAME=%~1"
set "APP_DIR=%FRONTEND_DIR%\apps\%APP_NAME%"

if not exist "%APP_DIR%" (
    echo [ERROR] App directory not found: %APP_DIR%
    exit /b 1
)

echo --------------------------------------------------------
echo Building %APP_NAME% [Release - Split per ABI]...
echo --------------------------------------------------------

cd /d "%APP_DIR%"
call flutter build apk --release --split-per-abi
set "STATUS=%ERRORLEVEL%"
cd /d "%ROOT_DIR%"

if %STATUS% neq 0 (
    echo [ERROR] Build failed for %APP_NAME% with exit code %STATUS%
    exit /b %STATUS%
)

echo.
echo Generated APKs for %APP_NAME%:
for %%A in ("%APP_DIR%\build\app\outputs\flutter-apk\app-*-release.apk") do (
    echo   - %%~nxA [%%~zA bytes] : %%A
)
echo.
exit /b 0
