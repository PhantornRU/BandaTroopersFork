@echo off
setlocal enabledelayedexpansion

echo ========================================================
echo Generating PNGs for all cases in tools\world_edit_visual\out\
echo ========================================================

set COUNT=0
set SUCCESS=0

for /d %%d in (tools\world_edit_visual\out\*) do (
    set /a COUNT+=1
    set "CASE_DIR=%%d"
    set "CASE_NAME=%%~nxd"
    echo.
    echo Processing !CASE_NAME!...
    
    if exist "!CASE_DIR!\semantic.json" (
        set REPORT_ARG=
        if exist "!CASE_DIR!\report.json" (
            set "REPORT_ARG=--report-json "!CASE_DIR!\report.json""
        )
        
        py -3 tools\world_edit_visual\render_semantic.py --semantic-json "!CASE_DIR!\semantic.json" !REPORT_ARG! --out "!CASE_DIR!\semantic.png"
        if !ERRORLEVEL! EQU 0 (
            echo [+] Rendered PNG saved to !CASE_DIR!\semantic.png
            set /a SUCCESS+=1
        ) else (
            echo [-] Failed to render PNG for !CASE_NAME!
        )
    ) else (
        echo [!] Skipping !CASE_NAME! - semantic.json not found
    )
)

echo.
echo ========================================================
echo Finished: Processed !SUCCESS!/!COUNT! cases successfully.
echo ========================================================
