@echo off
setlocal enabledelayedexpansion

set "ROOT_DIR=%~dp0"
set "BACKEND_DIR=%ROOT_DIR%backend"
set "TOOLS_DIR=%ROOT_DIR%.tools"
set "JDK_DIR=%TOOLS_DIR%\jdk-21"

echo ========================================================
echo [Step 1] Triggering build via build.bat...
echo ========================================================

call "%ROOT_DIR%build.bat"
if %ERRORLEVEL% neq 0 (
    echo [ERROR] Build failed with exit code %ERRORLEVEL%. Aborting run.
    exit /b %ERRORLEVEL%
)

echo ========================================================
echo [Step 2] Locating executable JAR...
echo ========================================================

rem Configure Java runtime environment
if exist "%JDK_DIR%\bin\java.exe" (
    set "JAVA_HOME=%JDK_DIR%"
    set "PATH=%JDK_DIR%\bin;!PATH!"
) else if defined JAVA_HOME (
    if exist "%JAVA_HOME%\bin\java.exe" (
        set "PATH=%JAVA_HOME%\bin;!PATH!"
    )
)

set "TARGET_JAR="
for %%F in ("%BACKEND_DIR%\target\*.jar") do (
    set "FNAME=%%~nxF"
    if not "!FNAME:~-13!"==".jar.original" (
        if not "!FNAME:~-12!"=="-sources.jar" (
            if not "!FNAME:~-12!"=="-javadoc.jar" (
                set "TARGET_JAR=%%F"
            )
        )
    )
)

if not defined TARGET_JAR (
    echo [ERROR] Executable JAR not found in %BACKEND_DIR%\target
    exit /b 1
)

echo Executable JAR: %TARGET_JAR%

echo ========================================================
echo [Step 3] Loading environment variables from file...
echo ========================================================

set "ENV_FILE="
if exist "%ROOT_DIR%.env" (
    set "ENV_FILE=%ROOT_DIR%.env"
) else if exist "%ROOT_DIR%.env.local" (
    set "ENV_FILE=%ROOT_DIR%.env.local"
) else if exist "%BACKEND_DIR%\.env" (
    set "ENV_FILE=%BACKEND_DIR%\.env"
)

if defined ENV_FILE (
    echo Loading variables from: %ENV_FILE%
    for /f "usebackq eol=# tokens=1* delims==" %%A in ("%ENV_FILE%") do (
        set "K=%%A"
        set "V=%%B"
        if defined K if defined V (
            call :SET_ENV "%%A" "%%B"
        )
    )
) else (
    echo No .env file found (checked %ROOT_DIR%.env, %ROOT_DIR%.env.local, %BACKEND_DIR%\.env).
    echo Using system environment / default application.properties.
)

echo ========================================================
echo [Step 4] Running application...
echo ========================================================

cd /d "%BACKEND_DIR%"
java.exe -jar "%TARGET_JAR%" %*
set "APP_STATUS=%ERRORLEVEL%"
cd /d "%ROOT_DIR%"

exit /b %APP_STATUS%

:SET_ENV
set "ENV_KEY=%~1"
set "ENV_VAL=%~2"
if defined ENV_KEY if defined ENV_VAL (
    rem Trim leading/trailing whitespace from key
    for /f "tokens=* delims= " %%X in ("%ENV_KEY%") do set "ENV_KEY=%%X"
    set "%ENV_KEY%=%ENV_VAL%"
    echo   [ENV] %ENV_KEY% set
)
goto :eof
