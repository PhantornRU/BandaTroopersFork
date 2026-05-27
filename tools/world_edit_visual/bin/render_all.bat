@echo off
setlocal
chcp 65001 >nul
cd /d "%~dp0\..\..\.."

py -3 -u tools\world_edit_visual\scripts\render_workflow.py
exit /b %ERRORLEVEL%
