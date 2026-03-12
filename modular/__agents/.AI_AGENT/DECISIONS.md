# DECISIONS

## D-001: Keep Human AI speech localization modular-first
- Decision: store Russian AI line banks in `modular/halo/**` and apply them at runtime to existing `human_ai_faction` datums.
- Why: directly rewriting 1400+ upstream strings in `code/**` would create a large sync-hostile diff.

## D-002: Covenant species split happens after brain creation
- Decision: apply Sangheili and Unggoy speech profiles through existing `modular_apply_human_ai_brain_overrides` hooks in HALO equipment presets.
- Why: both species share `FACTION_COVENANT`, so faction-level localization alone cannot preserve their distinct HALO voices.

## D-003: Missing faction categories use Russian fallback banks
- Decision: if a faction leaves any communication category empty, the fresh AI brain receives a Russian fallback list for that category.
- Why: several factions define only partial speech banks, and leaving the defaults untouched would leak stock English lines.

## D-004: Emote tokens stay untranslated
- Decision: preserve `*warcry`, `*pain`, and `*scream` exactly as command tokens.
- Why: they trigger emotes rather than player-visible natural-language text.
