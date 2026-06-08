# GitHub API Reference для импорта бинарных файлов

## Raw Content API

GitHub предоставляет API для получения raw-содержимого файла:

```
GET /repos/{owner}/{repo}/contents/{path}
```

### Параметры

| Параметр | Значение | Описание |
|----------|----------|----------|
| `Accept` | `application/vnd.github.raw` | Возвращает чистые бинарные данные (не base64) |
| `ref` | `refs/pull/{PR}/head` | Указывает на HEAD ветки Pull Request |

### Формат URL

```
https://api.github.com/repos/{owner}/{repo}/contents/{path}?ref=refs/pull/{PR}/head
```

### Примеры ref

| ref | Назначение |
|-----|------------|
| `refs/pull/1271/head` | HEAD ветки PR #1271 |
| `refs/heads/master` | Ветка master |
| `refs/tags/v1.0` | Тег v1.0 |
| `main` | Краткая форма (только для веток) |

## Поддерживаемые репозитории CM-PVE

| Репозиторий | Сокращение | Описание |
|-------------|------------|----------|
| `cmss13-devs/cmss13-pve` | CM-PVE | Основной PVE-репозиторий |
| `cmss13-devs/cmss13-pve-halo` | CM-PVE-HALO | HALO-ветка PVE |

## Ограничения

- **Rate limit**: 5000 запросов/час для аутентифицированных пользователей (через `gh auth login`)
- **Размер файла**: до 1 MB через API (для больших файлов используй raw.githubusercontent.com)
- **Альтернатива для больших файлов**: `https://raw.githubusercontent.com/{owner}/{repo}/refs/pull/{PR}/head/{path}`

## Raw GitHub URL (альтернатива)

Для больших файлов >1MB:

```
https://raw.githubusercontent.com/{owner}/{repo}/refs/pull/{PR}/head/{path}
```

Через curl/wget:

```bash
curl -L -o output.dmi "https://raw.githubusercontent.com/cmss13-devs/cmss13-pve/refs/pull/1271/head/icons/mob/xenos/spider_guard.dmi"
```

## Типичные расширения бинарных файлов

| Расширение | Тип | Где лежат |
|------------|-----|-----------|
| `.dmi` | BYOND icon | `icons/**/*.dmi` |
| `.ogg` | Audio | `sound/**/*.ogg` |
| `.png` | PNG image | `icons/**/*.png`, `tgui/public/*.png` |
| `.jpg`/`.jpeg` | JPEG image | `icons/**/*.jpg` |
| `.webp` | WebP image | `icons/**/*.webp` |
| `.woff2` | Font | `interface/*.woff2` |