# PLAN

## Active task
Stabilize Admin Music Panel UX/input behavior on `codex/admin-music-panel`:
- accept track duration as either raw seconds or timecode (`1:57`, `01:57`, `1:02:03`);
- mirror resolved/loaded metadata title into the editable track title field;
- preserve launch settings and relevant UI focus/selection state across tab switches and window reopen instead of resetting to defaults.

## Scope
- `tgui/packages/tgui/interfaces/AdminMusicPanel/{index.tsx,sections.tsx,shared.ts}`
- `modular/admin/code/admin_music/{admin_music_panel.dm,admin_music_service.dm}` only if backend persistence/normalization needs adjustment
- task-state docs for this task

## Out of scope
- broad UI redesigns
- unrelated Admin Music Panel polish
- unrelated admin or TGUI refactors

## Acceptance criteria
- duration field accepts `117` and `1:57` for the same 117-second result
- metadata/title sync fills the editable track title, not only read-only summary areas
- playback mode / repeat / launch context do not reset unexpectedly on tab switch or reopen
- focus/selection does not bounce back to defaults during normal panel interactions
- `git diff --check` and relevant build/lint checks pass

## Outcome
- Implemented in `AdminMusicPanel` TGUI plus `admin_music_panel.dm`
- Acceptance criteria satisfied by local code review and green verification checks
