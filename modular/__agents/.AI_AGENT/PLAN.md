# Round Cinematics Rewrite

## Goal
Replace the current cryo intro and round outro implementation with a modular BYOND cinematics system under `modular/round_cinematics/**`.

## Contract

### MUST
- New logic lives in `modular/round_cinematics/**`.
- Intro starts from `play_opening_sequence()` and only for player-controlled human/marine cryo or latejoin.
- Outro starts once from the existing round-end hooks.
- V1 uses BYOND screen objects, fullscreen overlays, and maptext, not HTML or TGUI.
- Cleanup is idempotent and always clears locks and overlays.
- Upstream edits are minimal and marked `SS220 EDIT`.
- Admin verbs are reachable through `code/modules/admin/admin_verbs.dm` and delegate into modular admin procs.
- Legacy `modular/fullscreen/**` and `modular/round_outro/**` paths are removed or left unreachable after the rewrite.
- `git diff --check` and the DM build must pass.

### KEEP
- Existing non-cinematic systems stay untouched except for the minimal glue required to start or stop cinematics.
- Shared screen helpers stay where they already live if they are still used by other code.
- Unrelated dirty worktree changes are preserved.

### REJECT
- HTML or browser intro.
- Legacy browser outro proc.
- TGUI-based v1 cinematic flow.
- Broad HUD or action-system refactors just to hide or show the HUD.
- Single-path cleanup or state stored permanently on the human mob.

### CHECK
- Intro blocks pod exit attempts during the lock window and resumes cleanly.
- Intro cleanup works on skip, disconnect, exit, and force stop.
- Outro starts once per round and does not duplicate when hooks fire twice.
- Outcome resolution falls back in the order admin override > structured result > inconclusive.
- Death reasons and missing data have fallbacks instead of runtimes.

## Discovery inventory
- Current cryo entrypoint:
  - `code/modules/mob/living/carbon/human/human.dm:1686` `play_opening_sequence()`
- Current cryo exit entrypoints:
  - `code/game/machinery/cryopod.dm:452` `relaymove()`
  - `code/game/machinery/cryopod.dm:457` `verb/eject()`
  - `code/game/machinery/cryopod.dm:542` `go_out()`
- Current round-end entrypoints:
  - `code/game/gamemodes/colonialmarines/colonialmarines.dm:484` `declare_completion()`
  - `code/game/gamemodes/colonialmarines/huntergames.dm:396` `declare_completion()`
  - `code/game/gamemodes/colonialmarines/whiskey_outpost.dm:259` `declare_completion()`
  - `code/game/gamemodes/colonialmarines/xenovsxeno.dm:257` `declare_completion()`
  - `code/game/gamemodes/extended/extended.dm:37` `declare_completion()`
  - `code/game/gamemodes/extended/infection.dm:118` `declare_completion()`
- Admin verb wiring:
  - `code/modules/admin/admin_verbs.dm:98` `admin_verbs_admin`
- Existing visual helpers:
  - `code/modules/maptext_alerts/screen_alerts.dm:13` `play_screen_text()`
  - `code/_onclick/hud/fullscreen.dm:6` `overlay_fullscreen()`
  - `code/_onclick/hud/screen_objects.dm:10` `atom/movable/screen/text`
- Existing legacy paths:
  - `modular/fullscreen/_fullscreen.dme:3-5`
  - `modular/round_outro/_round_outro.dme:1-2`
- Shared hooks that currently carry the legacy intro lock:
  - `code/_onclick/hud/hud.dm:170-176`
  - `code/datums/action.dm:222-230`
  - `code/game/machinery/cryopod.dm:548-555`

## Old path audit
- `modular/fullscreen/**` is only the old intro browser path.
- `modular/round_outro/**` is only the old round-outro browser path.
- The current HUD/action hooks are legacy glue and should disappear if the new session layer fully owns HUD hiding.
- `AlertModal.tsx` is not part of the v1 cinematic path unless a later discovery proves otherwise.
