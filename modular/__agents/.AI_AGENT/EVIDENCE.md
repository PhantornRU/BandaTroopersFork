# EVIDENCE

## Discovery inventory
- Current cryo intro flow:
  - `code/modules/mob/living/carbon/human/human.dm:1686` `play_opening_sequence()` currently calls the HTML intro path.
- Current cryo exit flow:
  - `code/game/machinery/cryopod.dm:452` `relaymove()`
  - `code/game/machinery/cryopod.dm:457` `verb/eject()`
  - `code/game/machinery/cryopod.dm:542` `go_out()`
- Current intro lock glue:
  - `code/_onclick/hud/hud.dm:170-176`
  - `code/datums/action.dm:222-230`
  - `code/game/machinery/cryopod.dm:548-555`
- Current round-end flow:
  - `code/game/gamemodes/colonialmarines/colonialmarines.dm:484`
  - `code/game/gamemodes/colonialmarines/huntergames.dm:396`
  - `code/game/gamemodes/colonialmarines/whiskey_outpost.dm:259`
  - `code/game/gamemodes/colonialmarines/xenovsxeno.dm:257`
  - `code/game/gamemodes/extended/extended.dm:37`
  - `code/game/gamemodes/extended/infection.dm:118`
- Admin verb wiring:
  - `code/modules/admin/admin_verbs.dm:98`
- Existing screen helpers already available:
  - `code/modules/maptext_alerts/screen_alerts.dm:13`
  - `code/_onclick/hud/fullscreen.dm:6`
  - `code/_onclick/hud/screen_objects.dm:10`
- Legacy browser-only paths:
  - `modular/fullscreen/_fullscreen.dme:3-5`
  - `modular/round_outro/_round_outro.dme:1-2`

## Plan mapping challenge
- Status: PASS WITH RISKS.
- Risk: the current intro and outro are still browser-driven, so the rewrite must replace those paths rather than wrapping them.
- Risk: the current intro lock leaks into shared HUD/action procs, which is unnecessary if the session layer owns HUD removal and restore.
- Risk: round-end hooks fire from multiple game mode files, so the controller must dedupe repeated start calls.
- Mitigation: keep the controller state local, wire minimal upstream glue, and retire the legacy modules after the modular replacement is in place.

## Unavoidable upstream edits
- `code/modules/mob/living/carbon/human/human.dm` is the intro entrypoint.
- `code/game/machinery/cryopod.dm` is the exit gate for blocked/forced cleanup.
- `code/game/gamemodes/colonialmarines/colonialmarines.dm`
- `code/game/gamemodes/colonialmarines/huntergames.dm`
- `code/game/gamemodes/colonialmarines/whiskey_outpost.dm`
- `code/game/gamemodes/colonialmarines/xenovsxeno.dm`
- `code/game/gamemodes/extended/extended.dm`
- `code/game/gamemodes/extended/infection.dm`
- `code/modules/admin/admin_verbs.dm` for the new admin proc refs.

## Current implementation notes
- `modular/round_cinematics/**` now owns the intro/outro flow.
- Round-start reset is registered through the round cinematics modpack, so stale sessions and `outro_started` do not survive into the next round.
- Live outro preview is blocked while a real outro is active, and any lingering preview session is replaced when the live outro starts.
- Verification rerun after the fix: `git diff --check` clean and `BUILD.cmd` clean on 2026-06-21.
