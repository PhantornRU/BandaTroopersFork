# DECISIONS

## D-001: Missing icon failures are fixed by repointing to confirmed existing atlas states
- If the intended state already exists in the current atlas family, the type is pointed at that exact state.
- If the current icon file itself is wrong, the type is moved back to the existing canonical atlas/state pair.
- We are not importing or drawing new sprites without a confirmed local source of truth.

## D-002: `SYNTH_COMBAT` stays bound to the W-Y android species
- `SYNTH_COMBAT` is still used by Whiteout and generic combat-synthetic entrypoints.
- The duplicate legacy `/datum/species/synthetic/colonial/combat` lookup name must change instead of `wy_droid`.

## D-003: The CANC overlap is caused by a hidden subtype created by a proc path typo
- `/datum/equipment_preset/canc_dogwar/soldier/upp/pl_leader/load_gear` implicitly creates `/datum/equipment_preset/canc_dogwar/soldier/upp` and `/soldier/upp/pl_leader`.
- The proc path and the one remaining squad spawner callsite must be moved to `/datum/equipment_preset/canc_dogwar/upp/pl_leader`.

## D-004: `lv671` tag cleanup is a raw map sanitation fix
- CI catches `^\ttag = "icon` with `tools/ci/check_grep.sh`.
- The fix is to remove those generated var-edit lines directly, not to rewrite the potted plant type or the whole map.
