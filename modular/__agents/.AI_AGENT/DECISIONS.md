# DECISIONS

## D-001: Translate object text in place
- Decision: update HALO object strings directly inside `modular/halo/code/**`.
- Why: the repo has no general HALO object-localization layer, and existing `modular/localization` coverage is for AI speech rather than item metadata.

## D-002: Keep translation scope object-focused
- Decision: include static player-facing object text such as `name`, `desc`, `desc_lore`, injector examine/instruction strings, and object-specific `attack_verb`, but exclude broader gameplay/system chat messages.
- Why: this covers visible HALO objects without expanding the task into full gameplay text localization.

## D-003: Preserve canonical identifiers
- Decision: keep model codes and major abbreviations such as `MA5C`, `M6D`, `SRS99-AM`, `UNSC`, `ODST`, and `SPNKr` unchanged while translating surrounding nouns and descriptions into Russian.
- Why: this keeps franchise items recognizable and avoids accidental contract or readability regressions.
