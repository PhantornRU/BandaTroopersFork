@echo off
chcp 65001 >nul
set CASE_NAME=%~1
if "%CASE_NAME%"=="" (
  echo Usage: render_case_sprites.bat [case_name]
  echo Example: render_case_sprites.bat building_line_locked
  pause
  exit /b 1
)

set DATA_DIR=tools\world_edit_visual\out\%CASE_NAME%

if not exist "%DATA_DIR%\semantic.json" (
  echo Error: semantic.json not found in %DATA_DIR%
  echo Run run_case.bat %CASE_NAME% first and wait for DreamDaemon to process it.
  pause
  exit /b 1
)

set OUTPUT_IMAGE="%DATA_DIR%\semantic_sprites.png"

echo Rendering sprites to %OUTPUT_IMAGE%...
py -3 tools\world_edit_visual\scripts\render_sprites.py --semantic-json "%DATA_DIR%\semantic.json" --output %OUTPUT_IMAGE%

if %errorlevel% neq 0 (
  echo Render failed!
  pause
  exit /b %errorlevel%
)

echo Done! You can open %OUTPUT_IMAGE% to see the result.
pause
