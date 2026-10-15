@echo off
setlocal enabledelayedexpansion

set "ROOT_DIR=%~dp0"
set "BACKEND_DIR=%ROOT_DIR%backend"
set "TOOLS_DIR=%ROOT_DIR%.tools"
set "JDK_DIR=%TOOLS_DIR%\jdk-21"

echo ========================================================
echo [1/3] Checking Java environment...
echo ========================================================

rem 1. Check local portable JDK in .tools\jdk-21
if exist "%JDK_DIR%\bin\java.exe" (
    echo Local JDK found: %JDK_DIR%
    set "JAVA_HOME=%JDK_DIR%"
    set "PATH=%JDK_DIR%\bin;!PATH!"
    goto :VERIFY_JAVA
)

rem 2. Check system JAVA_HOME
if defined JAVA_HOME (
    if exist "%JAVA_HOME%\bin\java.exe" (
        echo Using JAVA_HOME: %JAVA_HOME%
        set "PATH=%JAVA_HOME%\bin;!PATH!"
        goto :VERIFY_JAVA
    )
)

rem 3. Check java on PATH
where java.exe >nul 2>&1
if %ERRORLEVEL% equ 0 (
    echo Java detected on system PATH.
    goto :VERIFY_JAVA
)

rem 4. Java missing - download OpenJDK 21
echo Java not found on this machine.
echo Auto-downloading OpenJDK 21 (Eclipse Temurin)...

if not exist "%TOOLS_DIR%" mkdir "%TOOLS_DIR%"
set "ZIP_PATH=%TOOLS_DIR%\jdk21.zip"
set "EXTRACT_DIR=%TOOLS_DIR%\jdk_extract"
set "JDK_URL=https://api.adoptium.net/v3/binary/latest/21/ga/windows/x64/jdk/hotspot/normal/eclipse?project=jdk"

where curl.exe >nul 2>&1
if %ERRORLEVEL% equ 0 (
    echo Downloading via curl: %JDK_URL%
    curl.exe -L -f -o "%ZIP_PATH%" "%JDK_URL%"
) else (
    echo Downloading via PowerShell: %JDK_URL%
    powershell.exe -NoProfile -Command "[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; (New-Object System.Net.WebClient).DownloadFile('%JDK_URL%', '%ZIP_PATH%')"
)

if not exist "%ZIP_PATH%" (
    echo [ERROR] Failed to download JDK 21. Check network connection.
    exit /b 1
)

echo Extracting JDK 21...
if exist "%EXTRACT_DIR%" rmdir /s /q "%EXTRACT_DIR%"
mkdir "%EXTRACT_DIR%"

where tar.exe >nul 2>&1
if %ERRORLEVEL% equ 0 (
    tar.exe -xf "%ZIP_PATH%" -C "%EXTRACT_DIR%"
) else (
    powershell.exe -NoProfile -Command "Expand-Archive -LiteralPath '%ZIP_PATH%' -DestinationPath '%EXTRACT_DIR%' -Force"
)

del /f /q "%ZIP_PATH%" >nul 2>&1

for /d %%D in ("%EXTRACT_DIR%\*") do (
    if exist "%%D\bin\java.exe" (
        if exist "%JDK_DIR%" rmdir /s /q "%JDK_DIR%"
        move "%%D" "%JDK_DIR%" >nul
    )
)
rmdir /s /q "%EXTRACT_DIR%" >nul 2>&1

if not exist "%JDK_DIR%\bin\java.exe" (
    echo [ERROR] Failed to configure extracted JDK.
    exit /b 1
)

echo Successfully installed local JDK 21 at: %JDK_DIR%
set "JAVA_HOME=%JDK_DIR%"
set "PATH=%JDK_DIR%\bin;!PATH!"

:VERIFY_JAVA
java.exe -version
if %ERRORLEVEL% neq 0 (
    echo [ERROR] Java verification failed.
    exit /b 1
)

echo ========================================================
echo [2/3] Building backend JAR with Maven wrapper...
echo ========================================================

if not exist "%BACKEND_DIR%\mvnw.cmd" (
    echo [ERROR] Maven wrapper not found in %BACKEND_DIR%
    exit /b 1
)

cd /d "%BACKEND_DIR%"
set "MVN_ARGS=-DskipTests"
if not "%~1"=="" set "MVN_ARGS=%*"
call "%BACKEND_DIR%\mvnw.cmd" clean package %MVN_ARGS%
set "BUILD_STATUS=%ERRORLEVEL%"
cd /d "%ROOT_DIR%"

if %BUILD_STATUS% neq 0 (
    echo ========================================================
    echo [ERROR] BUILD FAILED with exit code %BUILD_STATUS%
    echo ========================================================
    exit /b %BUILD_STATUS%
)

echo ========================================================
echo [3/3] Build SUCCESS!
echo ========================================================
if exist "%BACKEND_DIR%\src\main\resources\application.properties" (
    copy /y "%BACKEND_DIR%\src\main\resources\application.properties" "%BACKEND_DIR%\target\application.properties" >nul
    echo Config copied: %BACKEND_DIR%\target\application.properties
)
for %%F in ("%BACKEND_DIR%\target\*.jar") do (
    set "FNAME=%%~nxF"
    if not "!FNAME:~-13!"==".jar.original" (
        echo Output JAR: %%F (%%~zF bytes)
    )
)

exit /b 0
