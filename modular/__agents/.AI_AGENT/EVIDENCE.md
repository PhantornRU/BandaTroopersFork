# EVIDENCE

## Confirmed root causes
- Duration editor only accepted numbers because `TrackInspectorSection` used `NumberInput` and `index.tsx` forwarded `duration_seconds` as a numeric field to `set_variant_duration`. Backend parsing was `text2num`-only in `modular/admin/code/admin_music/admin_music_panel.dm`.
- Preset name editor desynced from header/title because `PresetMetaSection` used raw `Input` with `onInput`, while the underlying `Input` component only applies its `value` prop on mount.
- Launch settings (`repeat`, `playback_mode`, etc.) were stored only in local React state and reset on every `draft_token` through `buildLaunchSettings(draft)`.
- `PlayTab` and `EditTab` were conditionally rendered, so switching tabs unmounted one subtree and reset its local search/focus state.

## Implemented fixes
- `tgui/packages/tgui/interfaces/AdminMusicPanel/shared.ts`
  - added `parseDurationInput(...)`, `formatDurationInputValue(...)`
  - added `coerceLaunchSettings(...)`
  - added persisted Admin Music Panel UI-state helpers over `common/storage`
- `tgui/packages/tgui/interfaces/AdminMusicPanel/sections.tsx`
  - added `BufferedDurationInput`
  - switched preset name field to `BufferedInput`
  - replaced `NumberInput` duration editor with buffered text duration parsing
- `tgui/packages/tgui/interfaces/AdminMusicPanel/index.tsx`
  - hydrate/persist `activeTab` and `launchSettings`
  - stop remounting `PlayTab`/`EditTab` on tab switch
- `modular/admin/code/admin_music/admin_music_panel.dm`
  - added backend duration parser for integer and timecode input

## Verification
- `git diff --check`
- `tools/build/build --ci lint tgui-test`
- `tools/build/build --ci dm -DCIBUILDING -DANSICOLORS -Werror`
