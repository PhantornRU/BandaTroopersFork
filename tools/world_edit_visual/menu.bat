@echo off
setlocal enabledelayedexpansion

:: Переходим в корень проекта (BandaTroopers)
cd /d "%~dp0\..\.."

:main_menu
cls
echo ========================================================
echo World Edit Visual Workbench - Главное меню
echo ========================================================
echo.
echo Доступные действия:
echo [1] Отправить все кейсы в inbox (запуск генерации)
echo [2] Сгенерировать PNG для всех готовых кейсов (из out/)
echo [3] Выбрать конкретный кейс для действий
echo [4] Выход
echo.

set /p action="Выберите действие (1-4): "

if "%action%"=="1" goto do_run_all
if "%action%"=="2" goto do_render_all_png
if "%action%"=="3" goto select_case
if "%action%"=="4" goto exit_script

goto main_menu

:do_run_all
cls
call tools\world_edit_visual\run_all.bat
pause
goto main_menu

:do_render_all_png
cls
call tools\world_edit_visual\render_all_png.bat
pause
goto main_menu

:select_case
cls
echo ========================================================
echo Выберите кейс:
echo ========================================================
set count=0
for %%f in (tools\world_edit_visual\cases\*.json) do (
    set /a count+=1
    set "case_file[!count!]=%%~nxf"
    set "case_name[!count!]=%%~nf"
    echo [!count!] %%~nxf
)
echo.
echo [0] Назад в главное меню
echo.

set /p case_choice="Выберите номер: "
if "%case_choice%"=="0" goto main_menu

set "selected_file=!case_file[%case_choice%]!"
set "selected_name=!case_name[%case_choice%]!"

if "%selected_file%"=="" (
    echo Неверный выбор!
    pause
    goto select_case
)

:case_action
cls
echo ========================================================
echo Выбран кейс: %selected_file%
echo ========================================================
echo.
echo Доступные действия:
echo [1] Отправить в inbox (запустить генерацию в игре)
echo [2] Отрендерить ASCII (требует готовый результат в out/)
echo [3] Отрендерить PNG (требует готовый результат в out/)
echo [4] Выбрать другой кейс
echo [0] Назад в главное меню
echo.

set /p action_choice="Выберите действие: "

if "%action_choice%"=="1" (
    call tools\world_edit_visual\run_case.bat "tools\world_edit_visual\cases\!selected_file!"
    pause
    goto case_action
)
if "%action_choice%"=="2" (
    call tools\world_edit_visual\render_case_ascii.bat "!selected_name!"
    pause
    goto case_action
)
if "%action_choice%"=="3" (
    call tools\world_edit_visual\render_case_png.bat "!selected_name!"
    pause
    goto case_action
)
if "%action_choice%"=="4" goto select_case
if "%action_choice%"=="0" goto main_menu

goto case_action

:exit_script
exit /b 0
