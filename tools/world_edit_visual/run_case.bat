@echo off
set CASE_FILE=%1
if "%CASE_FILE%"=="" (
  echo Usage: run_case.bat tools\world_edit_visual\cases\case.json
  exit /b 1
)

py -3 tools\world_edit_visual\prepare_cases.py "%CASE_FILE%"
echo Case prepared in data\world_edit_visual. Ensure DreamDaemon is running with World Edit Visual Workbench enabled.
