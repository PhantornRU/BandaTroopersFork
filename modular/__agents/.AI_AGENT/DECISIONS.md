# DECISIONS

## D-001: Keep HALO TTS selection data HALO-local
- Decision: store canonical HALO race packs and defaults in `modular/halo/.../halo_tts.dm`.
- Why: the shortlist is Halo content logic on top of the shared TTS module, so the data belongs in `modular/halo/**`, not in upstream or the generic TTS seed registry.

## D-002: Preserve explicit player preferences
- Decision: skip the HALO race default whenever `client.prefs.tts_seed` resolves to an available seed.
- Why: the task is to provide race defaults, not to override a player's deliberate voice choice.

## D-003: Apply the default in two phases
- Decision: apply the HALO race default both from `species.handle_post_spawn()` and again after HALO `load_preset()`.
- Why: species changes outside equipment presets should still get the correct default, and preset-level reapplication keeps randomised preset flows from drifting back to a generic random TTS seed.
