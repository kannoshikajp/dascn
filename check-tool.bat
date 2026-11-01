@echo off
setlocal enabledelayedexpansion

set "ROOT_DIR=%~dp0"
set "TOOLS_DIR=%ROOT_DIR%.tools"
set "TASK_EXE=%TOOLS_DIR%\task.exe"

rem 1. Check if Task CLI exists; if missing, call bootstrap.bat
if not exist "%TASK_EXE%" (
    where task.exe >nul 2>&1
    if !ERRORLEVEL! equ 0 (
        for /f "delims=" %%I in ('where task.exe') do set "TASK_EXE=%%I"
    ) else (
        echo [Check-Tool] Task CLI not found in .tools or PATH.
        echo Calling bootstrap.bat to install...
        call "%ROOT_DIR%bootstrap.bat"
        if !ERRORLEVEL! neq 0 (
            echo [ERROR] bootstrap.bat failed with exit code !ERRORLEVEL!.
            exit /b !ERRORLEVEL!
        )
    )
)

rem 2. If a target script was provided as argument, execute it
set "TARGET_BAT=%~1"
if not defined TARGET_BAT (
    exit /b 0
)

rem Shift first argument and forward remaining arguments
shift
set "PASS_ARGS="
:COLLECT_ARGS
if not "%~1"=="" (
    set "PASS_ARGS=!PASS_ARGS! %1"
    shift
    goto :COLLECT_ARGS
)

call "%TARGET_BAT%" !PASS_ARGS!
exit /b %ERRORLEVEL%
