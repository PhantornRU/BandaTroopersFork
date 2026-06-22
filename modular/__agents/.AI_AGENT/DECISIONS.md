# DECISIONS

## D-001: Use a dedicated modular controller
- Decision: build the feature around `GLOB.round_cinematics` backed by a `GLOBAL_DATUM_INIT(round_cinematics, /datum/round_cinematics_controller, new)`.
- Why: the repo already uses global datums for service-style state, and the cinematics flow needs shared session ownership without a new subsystem.

## D-002: Keep cinematic state inside session datums
- Decision: store intro and outro state in per-session datums, not on the human mob or the client.
- Why: the same controller needs to handle cleanup, idempotence, disconnects, and round-end dedupe without leaking state into shared gameplay objects.

## D-003: Hide the HUD without rewriting shared HUD internals
- Decision: session code should snapshot and temporarily remove the affected client HUD objects instead of adding new global HUD/action gates.
- Why: the previous `cryo_intro_hud_locked` approach spread into shared HUD/action procs and is not needed if the session owns the overlay lifecycle.

## D-004: Remove legacy browser paths once the new module is wired
- Decision: retire `modular/fullscreen/**` and `modular/round_outro/**` after the modular replacement is in place.
- Why: those directories only implement the old browser-based cinematic route and would keep dead code reachable.

## D-005: Keep upstream glue minimal
- Decision: patch only the actual entrypoints in `human.dm`, `cryopod.dm`, and the round-end game mode files.
- Why: the new logic belongs in `modular/**`, and the upstream files should only delegate or block at the boundary.

## D-006: Do not require TGUI for v1
- Decision: do not depend on `AlertModal.tsx` or any TGUI flow for the first modular implementation.
- Why: the plan calls for BYOND screen objects, fullscreen overlays, and maptext for v1, and TGUI is an unnecessary second surface.

## D-007: Expose admin controls through existing admin verbs
- Decision: wire the round-cinematics admin procs through `code/modules/admin/admin_verbs.dm` instead of adding a separate UI entry surface.
- Why: the repo already exposes modular admin tools through verb refs, and that keeps the new feature reachable without a TGUI or browser panel.

## D-008: Reset round cinematics at round start
- Decision: register a round-start callback through the round cinematics modpack and call `cleanup_all("roundstart_reset")` there.
- Why: `GLOB.round_cinematics` is a long-lived global datum, so the active outro/intro state must be cleared between rounds instead of relying on one-off cleanup paths.

## D-009: Do not let preview sessions overlap a live outro
- Decision: block round-outro preview while a real outro is active, and replace any lingering preview session before starting the live outro.
- Why: preview is an admin-only inspection path, and it must not preempt or double-stack the real round-end sessions on the same client.
