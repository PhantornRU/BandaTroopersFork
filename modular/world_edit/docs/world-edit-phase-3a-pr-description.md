# About the pull request

Реализует World Edit как полноценный in-game admin tool для GM/admin workflow с безопасным preview/apply циклом, модульной архитектурой и cleanup/undo guardrails.

В рамках этого PR:
- добавлен модульный World Edit runtime с manager/UI/registry/presets/history
- добавлены active READY generators:
  - `outpost_radius`
  - `destruction_pack`
  - `blueprint_stamp`
- добавлены per-admin presets для рабочих генераторов
- добавлена Blueprint Lite library с server-side validation, preview и stamping
- добавлен placement runtime с `single/repeat`, shape support, direction support и cleanup на `stop_click_mode`/panel close
- добавлены shape runtime foundation и interactive collector flow для multi-point placement shapes
- добавлен outpost quality pass:
  - template families
  - deterministic barricade mix
  - openings / passage logic
  - shape-aware perimeter generation
- расширен Destruction Pack:
  - safe shuffle/scatter
  - owned persistent fire
  - controlled blast / ruin / collapse modes
  - explicit non-undoable policy for high-risk destructive actions
- выполнен panel polish / UX pass для Setup/Run flow
- удалены deprecated World Edit generator runtimes из active runtime surface
- синхронизированы registry/docs с текущим active generator surface

Сознательно не делалось:
- map/editor outside World Edit scope
- unrelated cleanup outside World Edit surface
- fake full undo for destructive blast/structural damage paths

# Explain why it's good for the game

Это даёт администрации и ГМам единый рабочий инструмент редактирования мира прямо в игре вместо набора разрозненных/legacy подходов.

Польза для проекта:
- повторяемые admin workflows уходят в единый preview/apply runtime
- structure stamping, outpost building и destruction теперь живут в одном безопасном UI-контуре
- placement modes, cleanup и history ведут себя предсказуемо
- destructive действия явно отделены по risk policy и не притворяются undoable там, где это небезопасно
- active runtime surface стал заметно чище за счёт удаления deprecated generator runtimes

# Testing Photographs and Procedure

Automated checks run:
- `tools/build/build.bat tgui-lint tgui-tsc`
- `tools/build/build.bat clean`
- `tools/build/build.bat dm`

Latest DM compile result:
- `0 errors, 0 warnings`

Manual/live validation:
- live in-game smoke was not run in this environment
- recommended smoke after checkout:
  - `blueprint_stamp`: load/preview/apply, rotation, collector shapes
  - `outpost_radius`: family variants, shape-aware footprint placement, repeat mode, undo
  - `destruction_pack`: shuffle/scatter, persistent fire cleanup, blast, ruin/collapse guardrails
  - panel close / `stop_click_mode` cleanup
  - blueprint library actions while placement mode is active

<details>
<summary>Screenshots & Videos</summary>

No live screenshots were captured in this environment.

</details>

# Changelog

:cl:
add: Added the modular World Edit admin tool with safe preview/apply, presets, and Blueprint Lite structure stamping.
admin: Added active World Edit generators for outpost building, blueprint stamping, and destruction workflows.
ui: Reworked the World Edit panel into a clearer Setup/Run flow with better placement state visibility.
qol: Added repeat placement, multi-point shape collection, and safer blueprint/placement interaction flow.
fix: Fixed placement cleanup, repeat placement, and blueprint library behavior while placement mode is active.
del: Removed deprecated World Edit generator runtimes from the active runtime surface.
refactor: Synced World Edit runtime, registry, and docs around the current active generator set.
/:cl:
