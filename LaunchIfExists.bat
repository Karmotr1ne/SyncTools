@echo off
set "TARGET=E:\Work Space\Code Project\SyncTools\RunSync.bat"
if exist "%TARGET%" (
  call "%TARGET%"
) else (
  echo [%date% %time%] Target script not found: %TARGET%>>"%~dp0sync_error.log"
)