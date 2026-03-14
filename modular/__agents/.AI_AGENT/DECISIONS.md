# DECISIONS

## D-001: Translate object text in place
- Decision: update HALO object strings directly inside `modular/halo/code/**`.
- Why: the repo has no general HALO object-localization layer, and existing `modular/localization` coverage is for AI speech rather than item metadata.

## D-002: Keep translation scope object-focused
- Decision: include static player-facing object text such as `name`, `desc`, `desc_lore`, injector examine/instruction strings, and object-specific `attack_verb`, but exclude broader gameplay/system chat messages.
- Why: this covers visible HALO objects without expanding the task into full gameplay text localization.

## D-003: Preserve canonical identifiers
- Decision: keep model codes and major abbreviations such as `MA5C`, `M6D`, `SRS99-AM`, `ODST`, and `SPNKr` unchanged, but render player-facing `UNSC` text canonically as `ККОН`.
- Why: this keeps franchise hardware recognizable while matching the requested Russian canon for the faction name.

## D-004: Translate HALO vendor selection labels in place
- Decision: translate HALO `listed_products` labels and related HALO vendor selectable gear strings directly in the HALO vending definitions.
- Why: HALO vendor selections are inline string data in the same content layer as the objects themselves, so translating them locally keeps scope tight and avoids a new localization surface.
