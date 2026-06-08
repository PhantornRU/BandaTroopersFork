---
name: pr-binary-import
description: Импорт бинарных файлов (.dmi, .ogg, .png, .jpg, .webp, .woff2, любые бинарные ассеты) из Pull Request репозиториев CM-PVE и CM-PVE-HALO через GitHub API (gh CLI). Используй при портировании PR, когда diff содержит бинарные файлы, которые 'gh pr diff' не может отобразить текстом.
---

# pr-binary-import

## Files

- [`scripts/download_pr_binary.cmd`](scripts/download_pr_binary.cmd) — execute to download a single binary file from a PR
- [`references/GITHUB_API_REFERENCE.md`](references/GITHUB_API_REFERENCE.md) — read when you need API details, rate limits, or alternative download methods

## When to use

- При портировании PR из upstream репозиториев (cmss13-devs/cmss13-pve, cmss13-devs/cmss13-pve-halo), когда `gh pr diff` показывает `Binary files differ` для `.dmi`, `.ogg`, `.png` и других бинарных файлов.
- Когда нужно скачать конкретный бинарный файл из определённой ветки PR.
- Когда diff PR содержит изменённые (не только новые) бинарные файлы.

## When NOT to use

- Если бинарный файл уже присутствует в локальном репозитории и не требует обновления.
- Если нужно скачать **текстовые** файлы — для них достаточно `gh pr diff`.
- Если `gh` CLI не установлен — используй `curl` или `wget` с GitHub raw URL.

## Inputs required

- **PR number** — номер Pull Request (например, `1271`, `1280`).
- **Repository** — `cmss13-devs/cmss13-pve` или `cmss13-devs/cmss13-pve-halo`.
- **File path in repo** — путь к файлу в upstream (например, `icons/mob/xenos/spider_guard.dmi`).
- **Local output path** — куда сохранить файл (например, `icons/mob/xenos/spider_guard.dmi`).

## Workflow

### 1. Определите, какие бинарные файлы нужны

Получите список изменённых файлов в PR:

```bash
gh pr diff --repo {owner}/{repo} {PR} --name-only
```

Отфильтруйте только бинарные расширения:

```bash
gh pr diff --repo cmss13-devs/cmss13-pve 1280 --name-only | findstr /I "\.dmi$ \.ogg$ \.png$"
```

Для PowerShell:

```powershell
gh pr diff --repo cmss13-devs/cmss13-pve 1280 --name-only | Select-String "\.dmi$|\.ogg$|\.png$"
```

### 2. Скачайте каждый бинарный файл

**Метод A (рекомендуемый) — gh CLI + GitHub raw API:**

```cmd
gh api -H "Accept: application/vnd.github.raw" ^
  repos/{owner}/{repo}/contents/{path}?ref=refs/pull/{PR}/head ^
  > {local_path}
```

Пример для одного файла:

```cmd
gh api -H "Accept: application/vnd.github.raw" ^
  repos/cmss13-devs/cmss13-pve/contents/icons/mob/xenos/spider_guard.dmi?ref=refs/pull/1271/head ^
  > icons/mob/xenos/spider_guard.dmi
```

**Метод B — скрипт `download_pr_binary.cmd`:**

Скрипт принимает аргументы: `PR repo remote_path local_path`

```cmd
scripts\download_pr_binary.cmd 1271 cmss13-devs/cmss13-pve icons/mob/xenos/spider_guard.dmi icons/mob/xenos/spider_guard.dmi
```

### 3. Пакетная загрузка нескольких файлов

Если нужно скачать много файлов из одного PR, используйте цикл:

**cmd.exe:**
```cmd
set REPO=cmss13-devs/cmss13-pve
set PR=1280
for %%f in (head_1 items_lefthand_1 items_righthand_1 suit_1) do (
  gh api -H "Accept: application/vnd.github.raw" ^
    repos/%REPO%/contents/icons/mob/humans/onmob/%%f.dmi?ref=refs/pull/%PR%/head ^
    > icons\mob\humans\onmob\%%f.dmi
)
```

**PowerShell:**
```powershell
$repo = "cmss13-devs/cmss13-pve"
$pr = 1280
$files = @("head_1","items_lefthand_1","items_righthand_1","suit_1")
foreach ($f in $files) {
  $url = "https://api.github.com/repos/$repo/contents/icons/mob/humans/onmob/$f.dmi?ref=refs/pull/$pr/head"
  Invoke-RestMethod -Uri $url -Headers @{"Accept"="application/vnd.github.raw"} -OutFile "icons/mob/humans/onmob/$f.dmi"
}
```

### 4. Проверьте результат

```bash
dir {local_path}
```

Убедитесь, что размер файла > 0 и соответствует ожидаемому (не 1 байт и не 151 байт — это размеры заглушек).

## Примеры

**Загрузка spider xeno иконок из PR #1271:**
```cmd
scripts\download_pr_binary.cmd 1271 cmss13-devs/cmss13-pve icons/mob/xenos/spider_guard.dmi icons/mob/xenos/spider_guard.dmi
scripts\download_pr_binary.cmd 1271 cmss13-devs/cmss13-pve icons/mob/xenos/spider_hunter.dmi icons/mob/xenos/spider_hunter.dmi
scripts\download_pr_binary.cmd 1271 cmss13-devs/cmss13-pve icons/mob/xenos/spider_nurse.dmi icons/mob/xenos/spider_nurse.dmi
scripts\download_pr_binary.cmd 1271 cmss13-devs/cmss13-pve icons/mob/xenos/giant_lizard.dmi icons/mob/xenos/giant_lizard.dmi
```

**Загрузка dog_war.dmi из PR #1280:**
```cmd
scripts\download_pr_binary.cmd 1280 cmss13-devs/cmss13-pve icons/obj/items/food/mre_food/dog_war.dmi icons/obj/items/food/mre_food/dog_war.dmi
```

**Загрузка звуков из PR #1282:**
```cmd
for %%f in (warcry_male_1 warcry_male_2 warcry_female_1) do (
  scripts\download_pr_binary.cmd 1282 cmss13-devs/cmss13-pve ^
    sound/voice/twe_warcry/%%f.ogg ^
    sound/voice/twe_warcry/%%f.ogg
)
```

## Скрипт

См. [`scripts/download_pr_binary.cmd`](scripts/download_pr_binary.cmd) — универсальный скрипт для скачивания одного файла.

## Troubleshooting

| Проблема | Причина | Решение |
|----------|---------|---------|
| `HTTP 404` | Файл не существует по указанному пути в PR | Проверь путь через `gh pr diff -- name-only` |
| `HTTP 403` | Rate limit GitHub API | Подожди или используй `gh auth refresh` |
| Файл 0 байт | Редирект `>` не сработал | Используй PowerShell: `Invoke-RestMethod -Uri $url -Headers @{"Accept"="application/vnd.github.raw"} -OutFile $local_path` |
| Файл 1 байт | Неверный `Accept` header | Убедись что используешь `Accept: application/vnd.github.raw` |
| `gh: command not found` | `gh` CLI не установлен | Установи `gh` или используй `curl` с raw GitHub URL |