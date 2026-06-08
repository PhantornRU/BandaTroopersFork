# DECISIONS

## Active Decisions for PR #129 Port

### D1: BT already has more advanced AI presets than upstream
**Decision**: НЕ заменять BT AI presets на upstream. BT имеет больше вариантов (sword, honor_guard, support_medical, suicide_bomber, specops factions).
**Result**: BT presets untouched. ✅

### D2: BT уже имеет FACTION_UNGGOY, FACTION_SANGHEILI, FACTION_KIGYAR в mode.dm
**Decision**: Добавить только `FACTION_LIST_COVENANT`.
**Result**: Already present with specops variants. ✅

### D3: BT уже имеет stealth armor в covenant_master_sync.dm
**Decision**: Не создавать отдельные файлы — BT уже имеет covenant_stealth_armor_master_sync.dm.
**Result**: Existing files used. ✅

### D4: Helper procs (_select_equipment.dm)
**Decision**: BT уже имеет weapon package helpers в unggoy.dm и ruuhtian.dm.
**Result**: No new files needed. ✅

### D5: BT gear presets уже используют helper-паттерн
**Decision**: Добавить только `faction_group`.
**Result**: Added to sangheili.dm and unggoy.dm. ✅

### D6: Non-HALO AI системы в code/
**Decision**: НЕ комментировать non-HALO AI пресеты. BT — комбинированная CM+HALO сборка. Upstream PR #129 делал это для HALO-only ветки.
**Result**: M7, M8 intentionally DEVIATED. CM factions remain active. ✅

### D7: Compile check
**Result**: `tools/build/build.bat dm -DCIBUILDING -DANSICOLORS -Werror` → 0 errors, 0 warnings. ✅
