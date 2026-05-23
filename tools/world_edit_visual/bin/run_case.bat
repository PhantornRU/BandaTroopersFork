@echo off
chcp 65001 >nul
set CASE_FILE=%1
if "%CASE_FILE%"=="" (
  echo Usage: run_case.bat tools\world_edit_visual\cases\case.json
  pause
  exit /b 1
)

py -3 tools\world_edit_visual\scripts\prepare_cases.py "%CASE_FILE%"
echo Case prepared in tools\world_edit_visual. Ensure DreamDaemon is running with World Edit Visual Workbench enabled.
pause
