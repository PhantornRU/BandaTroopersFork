# EVIDENCE

## E-001: PR context
- Активная ветка: `halo_jackal_spartan_wave_apr2026`.
- `gh pr view --json number,title,url,baseRefName,headRefName,mergeStateStatus` показал PR `#94` -> `master`, `mergeStateStatus = DIRTY`.

## E-002: Подтвержденный lint symptom
- `modular/halo/code/mixed/components/spartan_jump.dm:103` вызывает `jumper.animation_spin(..., anim_flags = ANIMATION_PARALLEL)`.
- Сигнатура `/atom/proc/animation_spin` в `code/modules/animations/animation_library.dm` не принимает keyword `anim_flags`.

## E-003: Подтвержденные actionable review areas
- `halo_languages.dm`: mojibake в русских строках.
- `spartan_actions.dm`: `lunge/use_ability()` приводит `affected_atom` к carbon без type guard.
- `halo_spartan_keybindings.dm`: `Strength` сидит на `B`, что конфликтует с living `Resist`.
- `human_attackhand.dm` + `human_defense.dm`: Mjolnir absorption сейчас съедает punch feedback и игнорирует `damage` в `armor_degrade()`.
- `gun.dm`: `SKILL_FIREARMS * SKILL_GUN_HO` используется как multiplier минимум в accuracy/scatter/recoil и требует проверки на согласованность.

## E-004: Merge conflict surface
- `git merge --no-ff upstream/master` дал конфликты только в двух HALO файлах:
  - `modular/halo/__docs/HALO_PORT_BACKLOG.md`
  - `modular/halo/code/game/objects/items/storage/halo/halo_storageitems.dm`
- Остальной update wave смержился автоматически.

## E-005: Проверки после фиксов
- `git diff --check`: passed.
- `tools/build/build.bat --ci dm -DCIBUILDING -DANSICOLORS -Werror`: passed.
- Compile результат: `colonialmarines.dmb - 0 errors, 0 warnings` (`2026-04-13`).
