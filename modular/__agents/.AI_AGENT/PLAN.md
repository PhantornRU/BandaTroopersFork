# PLAN

## Active task
Translate player-facing HALO object text and HALO vendor product labels into Russian, using canonical `ККОН` for player-facing `UNSC`, without changing behavior, typepaths, config surfaces, or include graph.

## Delivery status
- [x] Re-scope task-state from the previous HALO bugfix to the HALO object translation task.
- [x] Translate HALO weapons, ammo, and related static text under `modular/halo/code/modules/projectiles/guns/halo/**`.
- [x] Translate HALO carried-item text under `modular/halo/code/game/objects/items/**` and HALO vending/storage/medical files.
- [x] Translate HALO wearable text under `modular/halo/code/mixed/clothing/**` and `modular/halo/code/modules/clothing/**`.
- [x] Translate remaining visible HALO structure, machinery, loose-item, and organ text under the remaining scoped files.
- [x] Translate HALO vendor `listed_products` and related selectable gear labels under HALO vending files.
- [x] Normalize player-facing `UNSC` wording to canonical `ККОН` where applicable.
- [x] Run text-safety and compile verification.

## Acceptance status
- Verified: touched HALO object names, descriptions, related static examine text, and HALO vendor labels are consistently Russian in the scoped files.
- Verified: model codes and major abbreviations such as `MA5C`, `M6D`, `SRS99-AM`, `ODST`, and `SPNKr` remain recognizable, while player-facing `UNSC` text is rendered canonically as `ККОН`.
- Verified: touched files remain valid UTF-8 with no mojibake and compile cleanly.
