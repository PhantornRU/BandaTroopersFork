@echo off
chcp 65001 >nul
py -3 tools\world_edit_visual\scripts\prepare_cases.py tools\world_edit_visual\cases
echo Cases prepared in tools\world_edit_visual. Run scripts\watch_cases.py in a second terminal to render PNGs.
pause
