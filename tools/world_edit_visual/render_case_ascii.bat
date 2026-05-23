@echo off
set CASE_NAME=%~1
if "%CASE_NAME%"=="" (
  echo Usage: render_case_ascii.bat [case_name]
  echo Example: render_case_ascii.bat building_line_locked
  exit /b 1
)

set DATA_DIR=tools\world_edit_visual\out\%CASE_NAME%

if not exist "%DATA_DIR%\semantic.json" (
  echo Error: semantic.json not found in %DATA_DIR%
  echo Run run_case.bat %CASE_NAME% first and wait for DreamDaemon to process it.
  exit /b 1
)

set REPORT_ARG=
if exist "%DATA_DIR%\report.json" (
  set REPORT_ARG=--report-json "%DATA_DIR%\report.json"
)

py -3 tools\world_edit_visual\render_ascii_map.py --semantic-json "%DATA_DIR%\semantic.json" %REPORT_ARG%
