@echo off
set CASE_NAME=%~1
if "%CASE_NAME%"=="" (
  echo Usage: render_case_png.bat [case_name]
  echo Example: render_case_png.bat building_line_locked
  exit /b 1
)

set DATA_DIR=tools\world_edit_visual\out\%CASE_NAME%
set OUT_FILE=%DATA_DIR%\semantic.png

if not exist "%DATA_DIR%\semantic.json" (
  echo Error: semantic.json not found in %DATA_DIR%
  echo Run run_case.bat %CASE_NAME% first and wait for DreamDaemon to process it.
  exit /b 1
)

set REPORT_ARG=
if exist "%DATA_DIR%\report.json" (
  set REPORT_ARG=--report-json "%DATA_DIR%\report.json"
)

py -3 tools\world_edit_visual\render_semantic.py --semantic-json "%DATA_DIR%\semantic.json" %REPORT_ARG% --out "%OUT_FILE%"
if %ERRORLEVEL% EQU 0 (
  echo Rendered PNG saved to %OUT_FILE%
) else (
  echo Failed to render PNG.
)
