@echo off
setlocal

:: ==== User paths (edit or pass as args) ====
set "PATH_A=E:\Data Library\Note"
set "PATH_B=F:\Note"
:: ==========================================

if not "%~1"=="" set "PATH_A=%~1"
if not "%~2"=="" set "PATH_B=%~2"

set "DRYRUN="
if /I "%~3"=="dryrun" set "DRYRUN=-DryRun"

if not exist "%PATH_A%" echo [ERROR] Missing A: "%PATH_A%" & exit /b 1
if not exist "%PATH_B%" echo [ERROR] Missing B: "%PATH_B%" & exit /b 1

set "SCRIPT_DIR=%~dp0"
powershell -NoProfile -ExecutionPolicy Bypass -File "%SCRIPT_DIR%Sync.ps1" -A "%PATH_A%" -B "%PATH_B%" %DRYRUN%

endlocal