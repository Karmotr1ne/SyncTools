@echo off
setlocal enabledelayedexpansion

:: Paths to watch (must match Sync.ps1)
set "PATH_A=E:\Data Library\Note"
set "PATH_B=F:\Note"

set "SCRIPT_DIR=%~dp0"
set "LOG=%SCRIPT_DIR%sync_supervisor.log"

:: Optional: /dryrun passes through to Sync.ps1
set "PS_DRYRUN="
if /i "%~1"=="/dryrun" set "PS_DRYRUN=-DryRun"

:: Check presence
if exist "%PATH_A%" (set "HAS_A=1") else (set "HAS_A=0")
if exist "%PATH_B%" (set "HAS_B=1") else (set "HAS_B=0")

if "%HAS_A%%HAS_B%"=="11" (
    echo [%date% %time%] Both present -> run sync >> "%LOG%"
    if exist "%SCRIPT_DIR%Sync.ps1" (
        powershell -NoProfile -ExecutionPolicy Bypass -File "%SCRIPT_DIR%Sync.ps1" %PS_DRYRUN%
        set "RC=!ERRORLEVEL!"
        if not "!RC!"=="0" (
            echo [%date% %time%] Sync returned !RC! >> "%LOG%"
        ) else (
            echo [%date% %time%] Sync OK >> "%LOG%"
        )
        exit /b !RC!
    ) else (
        echo [%date% %time%] WARNING: Sync.ps1 missing >> "%LOG%"
        exit /b 2
    )
) else (
    if "%HAS_A%"=="0" echo [%date% %time%] Skip: PATH_A missing: "%PATH_A%" >> "%LOG%"
    if "%HAS_B%"=="0" echo [%date% %time%] Skip: PATH_B missing: "%PATH_B%" >> "%LOG%"
    exit /b 0
)

endlocal