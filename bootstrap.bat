@echo off
setlocal enabledelayedexpansion

set "ROOT_DIR=%~dp0"
set "TOOLS_DIR=%ROOT_DIR%.tools"
set "TASK_EXE=%TOOLS_DIR%\task.exe"
set "ZIP_PATH=%TOOLS_DIR%\task_windows_amd64.zip"
set "TASK_URL=https://github.com/go-task/task/releases/latest/download/task_windows_amd64.zip"

echo ========================================================
echo [Bootstrap] Installing Task CLI to .tools...
echo ========================================================

rem 1. Check if task.exe is already installed (unless --force is passed)
if /i not "%~1"=="--force" (
    if exist "%TASK_EXE%" (
        echo Task CLI is already installed at:
        echo   %TASK_EXE%
        "%TASK_EXE%" --version
        echo Use 'bootstrap.bat --force' to re-download.
        exit /b 0
    )
)

rem 2. Ensure .tools directory exists
if not exist "%TOOLS_DIR%" mkdir "%TOOLS_DIR%"

rem 3. Download task_windows_amd64.zip
echo Downloading Task CLI from GitHub Releases...
echo Source: %TASK_URL%

where curl.exe >nul 2>&1
if %ERRORLEVEL% equ 0 (
    curl.exe -L -f -o "%ZIP_PATH%" "%TASK_URL%"
) else (
    powershell.exe -NoProfile -Command "[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; (New-Object System.Net.WebClient).DownloadFile('%TASK_URL%', '%ZIP_PATH%')"
)

if not exist "%ZIP_PATH%" (
    echo [ERROR] Failed to download Task CLI zip package.
    echo Please check your internet connection or download manually from:
    echo   https://github.com/go-task/task/releases
    exit /b 1
)

rem 4. Extract archive
echo Extracting Task CLI into %TOOLS_DIR%...
where tar.exe >nul 2>&1
if %ERRORLEVEL% equ 0 (
    tar.exe -xf "%ZIP_PATH%" -C "%TOOLS_DIR%"
) else (
    powershell.exe -NoProfile -Command "Expand-Archive -LiteralPath '%ZIP_PATH%' -DestinationPath '%TOOLS_DIR%' -Force"
)

rem Clean up temporary zip
if exist "%ZIP_PATH%" del /f /q "%ZIP_PATH%" >nul 2>&1

rem 5. Verify installation
if not exist "%TASK_EXE%" (
    echo [ERROR] task.exe not found after extraction.
    exit /b 1
)

echo.
echo ========================================================
echo [SUCCESS] Task CLI bootstrapped successfully!
echo Binary: %TASK_EXE%
"%TASK_EXE%" --version
echo ========================================================

exit /b 0
