@echo off
REM download_pr_binary.cmd — Скачать бинарный файл из Pull Request через GitHub API
REM
REM Usage:
REM   download_pr_binary.cmd <PR> <repo> <remote_path> <local_path>
REM
REM Пример:
REM   download_pr_binary.cmd 1271 cmss13-devs/cmss13-pve icons/mob/xenos/spider_guard.dmi icons/mob/xenos/spider_guard.dmi
REM
REM Зависимости: gh CLI (GitHub CLI)
REM
REM Как это работает:
REM   GitHub API с Accept: application/vnd.github.raw возвращает чистый бинарный файл.
REM   refs/pull/{PR}/head указывает на HEAD ветки Pull Request.
REM   Перенаправление > в cmd.exe сохраняет бинарные данные без повреждений.

setlocal EnableDelayedExpansion

set PR=%1
set REPO=%2
set REMOTE_PATH=%3
set LOCAL_PATH=%4

if "%PR%"=="" (
    echo Usage: download_pr_binary.cmd ^<PR^> ^<repo^> ^<remote_path^> ^<local_path^>
    echo Example: download_pr_binary.cmd 1271 cmss13-devs/cmss13-pve icons/mob/xenos/spider_guard.dmi icons/mob/xenos/spider_guard.dmi
    exit /b 1
)

echo [pr-binary-import] Downloading %REMOTE_PATH% from PR #%PR% (%REPO%)...
echo [pr-binary-import] Target: %LOCAL_PATH%

REM Create parent directory if needed
for %%F in ("%LOCAL_PATH%") do set LOCAL_DIR=%%~dpF
if not exist "%LOCAL_DIR%" mkdir "%LOCAL_DIR%"

gh api -H "Accept: application/vnd.github.raw" ^
    repos/%REPO%/contents/%REMOTE_PATH%?ref=refs/pull/%PR%/head ^
    > "%LOCAL_PATH%"

if %ERRORLEVEL% neq 0 (
    echo [pr-binary-import] ERROR: Failed to download %REMOTE_PATH%
    echo [pr-binary-import] Check that the file exists in PR #%PR% at path: %REMOTE_PATH%
    exit /b %ERRORLEVEL%
)

for %%F in ("%LOCAL_PATH%") do set FILE_SIZE=%%~zF
echo [pr-binary-import] Downloaded successfully: %FILE_SIZE% bytes
exit /b 0
