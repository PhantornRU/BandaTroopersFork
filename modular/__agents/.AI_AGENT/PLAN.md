# PLAN

## Active task
Implement HALO race-specific TTS defaults and canonical shortlist packs for `Sangheili` and `Unggoy`, while preserving explicit player `prefs.tts_seed`.

## Delivery status
- [x] Identify HALO-local speech cues and approved Silero shortlist/default seeds.
- [x] Add a HALO-local TTS helper with canonical packs and species defaults.
- [x] Apply HALO defaults from both species spawn and HALO equipment preset flows.
- [x] Preserve explicit player `prefs.tts_seed` instead of overwriting it with the race default.
- [x] Add focused unit tests for canonical packs, direct species application, and preset application.
- [x] Run targeted compile verification for `dm`.
- [x] Run `dm-test` through successful `.test.dmb` compilation; the Windows wrapper then hung and stopped exiting on its own.

## Acceptance status
- Confirmed by code and unit tests: `Sangheili` resolve to `Alarak` by default when no explicit player preference exists.
- Confirmed by code and unit tests: `Unggoy` resolve to `Dobby` by default when no explicit player preference exists.
- Confirmed by code and docs: canonical fallback packs remain queryable in code and documented in HALO docs.
- Confirmed by `tools/build/build --ci dm -DCIBUILDING -DANSICOLORS -Werror`: passed.
- Confirmed by `dm-test` compile output: `colonialmarines.test.dmb - 0 errors, 0 warnings`, but the Windows wrapper did not terminate cleanly afterward.
