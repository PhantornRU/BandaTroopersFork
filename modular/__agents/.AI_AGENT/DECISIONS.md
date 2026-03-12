# DECISIONS

## D-001: Keep Human AI speech localization modular-first
- Decision: store Russian AI line banks in a dedicated `modular/localization/**` modpack and apply them at runtime to existing `human_ai_faction` datums.
- Why: this matches SS220 modularity rules better than coupling shared localization data to `modular/halo/**`.

## D-002: Avoid global localization helper procs
- Decision: bind localization helpers to `/datum/modpack/localization` instead of free `/proc` helpers.
- Why: the localization logic is module-owned business logic and should not leak global utility surfaces.

## D-003: Covenant species split happens after brain creation
- Decision: apply Sangheili and Unggoy speech profiles through existing `modular_apply_human_ai_brain_overrides` hooks in HALO equipment presets.
- Why: both species share `FACTION_COVENANT`, so faction-level localization alone cannot preserve their distinct HALO voices.

## D-004: Missing faction categories use Russian fallback banks
- Decision: if a faction leaves any communication category empty, the fresh AI brain receives a Russian fallback list for that category through a minimal upstream post-create hook.
- Why: several factions define only partial speech banks, and leaving the defaults untouched would leak stock English lines.

## D-005: Emote tokens stay untranslated
- Decision: preserve `*warcry`, `*pain`, and `*scream` exactly as command tokens.
- Why: they trigger emotes rather than player-visible natural-language text.
