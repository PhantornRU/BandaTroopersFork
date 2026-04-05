# DECISIONS

## Confirmed implementation choices
- Duration input is fixed as a text-based buffered field in TGUI instead of extending `NumberInput`. This allows `117`, `1:57`, and `1:02:03` while still storing seconds in the model.
- `set_variant_duration` in `admin_music_panel.dm` now defensively parses both integer seconds and `mm:ss` / `hh:mm:ss` strings so the backend remains authoritative if the UI sends timecode.
- Preset name editing now uses the same buffered commit model as other Admin Music Panel text fields instead of a per-keystroke direct `Input`, fixing stale editable-name behavior relative to header/title display.
- Launch settings persistence is implemented through TGUI `panel-settings` storage plus `coerceLaunchSettings(...)`, rather than changing preset schema or service/session backend models.
- `PlayTab` and `EditTab` remain mounted and are hidden by style instead of being swapped by a ternary render, preserving local tab state across `Play/Edit` switches without broad refactors.
