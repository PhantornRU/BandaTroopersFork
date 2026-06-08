# Установка и настройка Headroom MCP для Zoo Code (Windows)

## 1. Назначение документа

Этот документ — самодостаточная инструкция по установке и настройке **Headroom MCP server** для **Zoo Code** на Windows. Инструкция переносима: другой Zoo Code (или человек) может выполнить шаги на чистом устройстве и получить работающий headroom.

Headroom — это инструмент сжатия контекста. Он перехватывает выводы тулов (логи, файлы, результаты поиска) и сжимает их до того, как они попадут в контекстное окно LLM. Экономия: **60–95% токенов**.

После настройки в Zoo Code становятся доступны три MCP-тула:
- `mcp--headroom--headroom_compress` — сжать контент
- `mcp--headroom--headroom_retrieve` — восстановить сжатый контент по хешу
- `mcp--headroom--headroom_stats` — статистика сжатия за сессию

---

## 2. Что устанавливается

| Компонент | Что это |
|---|---|
| `headroom` (Python package) | CLI-утилита и MCP-сервер, версия пакета `headroom-ai` |
| `headroom.exe` | Исполняемый файл CLI, устанавливается pip'ом в `Scripts` |
| MCP-конфигурация Zoo Code | JSON-файлы, в которых прописывается запуск `headroom mcp serve` |

Репозиторий: <https://github.com/chopratejas/headroom>

---

## 3. Требования

- **Windows 10/11**
- **Python 3.10+** (проверено на 3.13). На системе должен быть доступен `py` launcher или `python` в PATH.
- **Zoo Code** (VS Code extension)
- **PowerShell 5+**
- Интернет-соединение для `pip install`

---

## 4. Быстрая схема установки

```
Установить Python package → Найти headroom.exe → Прописать в MCP-файлы Zoo Code → Проверить JSON → Reload Window → Проверить registry
```

---

## 5. Подробная установка Python package

### 5.1. Проверка Python

Открой PowerShell и выполни:

```powershell
py --version
```

Если `py` недоступен, попробуй:

```powershell
python --version
```

Если ни одна команда не работает — установи Python с <https://python.org>. При установке отметь галочку «Add Python to PATH».

### 5.2. Установка headroom

**Важно:** Обычная команда `pip install "headroom-ai[mcp]"` может упасть с ошибкой линковки Rust/MSVC, потому что одна из зависимостей пытается собраться из исходников. Рабочий способ — использовать pre-built wheel:

```powershell
pip install --only-binary :all: "headroom-ai[mcp]"
```

Если эта команда тоже падает, попробуй:

```powershell
pip install --only-binary :all: "headroom-ai[mcp]" fastapi
```

(`fastapi` может не подтянуться автоматически как зависимость MCP-сервера, но требоваться CLI.)

### 5.3. Проверка установки

```powershell
headroom --version
```

Ожидаемый вывод: `headroom, version X.Y.Z` (например, `0.20.15`).

Если `headroom` не найден — см. раздел [Troubleshooting](#13-troubleshooting), пункт «headroom не в PATH».

---

## 6. Поиск `headroom.exe`

Точный путь к `headroom.exe` понадобится для MCP-конфигурации. Найди его:

```powershell
where headroom
```

Вывод будет похож на:

```
C:\Users\<USER>\AppData\Local\Programs\Python\Python313\Scripts\headroom.exe
```

Запомни этот путь. В конфигурационных файлах ниже он записан как шаблон:

```
C:\Users\<USER>\AppData\Local\Programs\Python\Python313\Scripts\headroom.exe
```

Замени `<USER>` на своё имя пользователя Windows. Узнать его можно командой:

```powershell
$env:USERNAME
```

Или использовать переменную окружения напрямую в пути (см. раздел 8).

---

## 7. Настройка MCP-файлов Zoo Code

Zoo Code читает MCP-конфигурацию из **двух** файлов. Для надёжности headroom нужно прописать в оба.

### 7.1. Файл 1: `C:\Users\<USER>\.roo\mcp.json`

Проверь, существует ли файл:

```powershell
Test-Path "$env:USERPROFILE\.roo\mcp.json"
```

Если файла нет — создай директорию и файл:

```powershell
New-Item -ItemType Directory -Force -Path "$env:USERPROFILE\.roo"
```

### 7.2. Файл 2: `C:\Users\<USER>\AppData\Roaming\Code\User\globalStorage\zoocodeorganization.zoo-code\settings\mcp_settings.json`

Проверь, существует ли файл:

```powershell
Test-Path "$env:APPDATA\Code\User\globalStorage\zoocodeorganization.zoo-code\settings\mcp_settings.json"
```

Если файла нет — Zoo Code создаст его автоматически при первом запуске. Можно создать вручную:

```powershell
$dir = "$env:APPDATA\Code\User\globalStorage\zoocodeorganization.zoo-code\settings"
New-Item -ItemType Directory -Force -Path $dir
```

---

## 8. Рабочий JSON-блок

Ниже — проверенная секция для добавления в каждый из двух файлов. **Замени `<USER>`** на своё имя пользователя Windows.

```json
"headroom": {
  "command": "cmd",
  "args": [
    "/c",
    "C:\\Users\\<USER>\\AppData\\Local\\Programs\\Python\\Python313\\Scripts\\headroom.exe",
    "mcp",
    "serve"
  ],
  "disabled": false,
  "alwaysAllow": []
}
```

### Важные замечания по формату

1. **Поля `disabled` и `alwaysAllow` обязательны.** Без них Zoo Code может показать ошибку «Неверный формат JSON настроек MCP».
2. **Слеши в пути:** используй двойные обратные слеши `\\` (экранирование в JSON).
3. **`command` — `cmd`**, не `headroom` напрямую. Аргумент `/c` запускает `headroom.exe mcp serve` через командную строку. Это надёжнее, чем прямой вызов `.exe` (избегает проблем с PATH и stdin/stdout).
4. Если Python установлен в другое место (например, `Python312`), подставь актуальный путь из вывода `where headroom`.

### Пример полного файла `mcp.json`

```json
{
  "mcpServers": {
    "headroom": {
      "command": "cmd",
      "args": [
        "/c",
        "C:\\Users\\<USER>\\AppData\\Local\\Programs\\Python\\Python313\\Scripts\\headroom.exe",
        "mcp",
        "serve"
      ],
      "disabled": false,
      "alwaysAllow": []
    }
  }
}
```

### Пример полного файла `mcp_settings.json`

```json
{
  "mcpServers": {
    "headroom": {
      "command": "cmd",
      "args": [
        "/c",
        "C:\\Users\\<USER>\\AppData\\Local\\Programs\\Python\\Python313\\Scripts\\headroom.exe",
        "mcp",
        "serve"
      ],
      "disabled": false,
      "alwaysAllow": []
    }
  }
}
```

> Если в файлах уже есть другие MCP-серверы, добавь секцию `"headroom"` внутрь существующего объекта `"mcpServers"`, соблюдая запятые между серверами.

---

## 9. Проверка до перезапуска Zoo Code

### 9.1. Проверка JSON-валидности (PowerShell)

```powershell
$path1 = "$env:USERPROFILE\.roo\mcp.json"
$path2 = "$env:APPDATA\Code\User\globalStorage\zoocodeorganization.zoo-code\settings\mcp_settings.json"

foreach ($p in $path1, $path2) {
    if (Test-Path $p) {
        try {
            $null = Get-Content $p -Raw | ConvertFrom-Json
            Write-Host "OK: $p"
        } catch {
            Write-Host "ERROR (invalid JSON): $p"
            Write-Host $_.Exception.Message
        }
    } else {
        Write-Host "SKIP (not found): $p"
    }
}
```

### 9.2. Проверка JSON-валидности (Python)

```powershell
python -c "import json; json.load(open(r'$env:USERPROFILE\.roo\mcp.json')); print('OK: mcp.json')"
python -c "import json; json.load(open(r'$env:APPDATA\Code\User\globalStorage\zoocodeorganization.zoo-code\settings\mcp_settings.json')); print('OK: mcp_settings.json')"
```

### 9.3. Проверка, что headroom MCP запускается

```powershell
headroom mcp serve --help
```

Должен показать help по MCP-команде. Сам сервер запускать вручную не нужно — Zoo Code сделает это автоматически.

---

## 10. Reload Window

После правки JSON-файлов **обязательно** перезагрузи окно Zoo Code:

1. Нажми `Ctrl+Shift+P`
2. Набери `Reload Window`
3. Нажми Enter

Zoo Code при загрузке прочитает MCP-конфигурацию и запустит headroom-сервер.

---

## 11. Проверка в Zoo Code registry

После перезагрузки открой любой чат с агентом Zoo Code и попроси:

> Покажи список доступных MCP tools

Агент должен показать registry, в котором присутствуют:

- `mcp--headroom--headroom_compress`
- `mcp--headroom--headroom_retrieve`
- `mcp--headroom--headroom_stats`

Если тулов нет — см. раздел [Troubleshooting](#13-troubleshooting), пункт «Нет tools в registry».

---

## 12. Проверка в subtasks через Orchestrator

Headroom доступен во всех режимах Zoo Code, включая подзадачи Orchestrator:

- Orchestrator → Architect
- Orchestrator → Code
- Orchestrator → Debug

Чтобы проверить, создай Orchestrator-задачу и в подзадаче попроси агента вызвать `headroom_stats`. Агент должен вернуть статистику сжатия (даже нулевую, если сжатие ещё не применялось).

---

## 13. Troubleshooting

### 13.1. `pip install` падает с ошибкой Rust/MSVC linker

**Симптом:**
```
error: can't find Rust compiler
error: linker `link.exe` not found
```

**Причина:** Одна из зависимостей headroom пытается собрать нативное расширение из исходников, требуя Rust и MSVC Build Tools.

**Решение:** Использовать `--only-binary :all:`:

```powershell
pip install --only-binary :all: "headroom-ai[mcp]"
```

Если не помогает — добавить `fastapi`:

```powershell
pip install --only-binary :all: "headroom-ai[mcp]" fastapi
```

### 13.2. `headroom` не в PATH

**Симптом:**
```
'headroom' is not recognized as an internal or external command
```

**Решение:**
1. Найти `headroom.exe` через полный путь:
   ```powershell
   Get-ChildItem -Path "$env:LOCALAPPDATA\Programs\Python" -Recurse -Filter "headroom.exe" -ErrorAction SilentlyContinue
   ```
2. Либо добавить `Scripts` в PATH:
   ```powershell
   $scriptsPath = "$env:LOCALAPPDATA\Programs\Python\Python313\Scripts"
   [Environment]::SetEnvironmentVariable("Path", "$env:Path;$scriptsPath", "User")
   ```
   Затем перезапустить терминал.

### 13.3. Нет tools в registry после Reload Window

**Возможные причины и решения:**

| Причина | Проверка | Решение |
|---|---|---|
| JSON невалиден | Проверить через PowerShell (раздел 9.1) | Исправить синтаксис |
| Неверный путь к `headroom.exe` | `where headroom` | Подставить актуальный путь |
| Нет полей `disabled` / `alwaysAllow` | Открыть JSON | Добавить оба поля (см. раздел 8) |
| Zoo Code не перезагружен | — | `Ctrl+Shift+P` → `Reload Window` |
| MCP-сервер упал при старте | Запустить `headroom mcp serve` вручную в терминале | Прочитать ошибку, исправить |
| Файл не в том месте | Проверить пути из раздела 7 | Zoo Code может читать только `mcp_settings.json`, а не `mcp.json` — прописать в оба |

### 13.4. «Неверный формат JSON настроек MCP»

**Симптом:** Zoo Code показывает красное уведомление/ошибку при старте.

**Решение:**
1. Убедись, что у **каждого** сервера в `mcpServers` есть поля `"disabled"` и `"alwaysAllow"`.
2. Проверь JSON на валидность (раздел 9.1).
3. Убедись, что нет висячих запятых (trailing commas) — JSON их не поддерживает.

### 13.5. GitHub/Docker server — не относится к headroom

Если в логах или issues упоминается «github server» или «Docker MCP server» — это **не связано** с headroom. Headroom — это standalone Python process, запускаемый через `cmd /c headroom.exe mcp serve`. Никаких контейнеров, Docker-образов или GitHub-интеграций не требуется.

### 13.6. Автоматическое сжатие всех outputs

Headroom предоставляет **tools**, которые агент может вызывать. Автоматическое сжатие **каждого** вывода тула зависит от workflow-правил конкретного агента и не гарантируется установкой MCP-сервера. Агент должен быть проинструктирован (или иметь встроенную логику) использовать `headroom_compress` для больших ответов. Сам факт наличия тулов в registry означает, что они **доступны для вызова**.

---

## 14. Итоговый чеклист

- [ ] Python установлен, `py --version` работает
- [ ] `pip install --only-binary :all: "headroom-ai[mcp]"` выполнен без ошибок
- [ ] `headroom --version` показывает версию
- [ ] `where headroom` возвращает путь к `.exe`
- [ ] Путь подставлен в JSON-блок (раздел 8) с правильным `<USER>`
- [ ] Секция `headroom` добавлена в `%USERPROFILE%\.roo\mcp.json`
- [ ] Секция `headroom` добавлена в `%APPDATA%\Code\User\globalStorage\zoocodeorganization.zoo-code\settings\mcp_settings.json`
- [ ] В обоих файлах есть поля `"disabled": false` и `"alwaysAllow": []`
- [ ] JSON-валидация пройдена (PowerShell или Python, раздел 9)
- [ ] Выполнен Reload Window (`Ctrl+Shift+P` → `Reload Window`)
- [ ] В registry видны три тула: `headroom_compress`, `headroom_retrieve`, `headroom_stats`
- [ ] Тулы доступны в Orchestrator-подзадачах
