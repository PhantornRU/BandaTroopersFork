# PLAN

## Active task
Translate player-facing HALO object text into Russian for Wave 1 without changing behavior, typepaths, config surfaces, or include graph.

## Delivery status
- [x] Re-scope task-state from the previous HALO bugfix to the HALO object translation task.
- [ ] Translate HALO weapons, ammo, and related static text under `modular/halo/code/modules/projectiles/guns/halo/**`.
- [ ] Translate HALO carried-item text under `modular/halo/code/game/objects/items/**` and HALO vending/storage/medical files.
- [ ] Translate HALO wearable text under `modular/halo/code/mixed/clothing/**` and `modular/halo/code/modules/clothing/**`.
- [ ] Translate remaining visible HALO structure, machinery, loose-item, and organ text under the remaining scoped files.
- [ ] Run text-safety and compile verification.

## Acceptance status
- Pending verification: touched HALO object names, descriptions, and related static examine text are consistently Russian.
- Pending verification: model codes and major abbreviations such as `MA5C`, `M6D`, `SRS99-AM`, `UNSC`, `ODST`, and `SPNKr` remain recognizable and unchanged.
- Pending verification: touched files remain valid UTF-8 with no mojibake and compile cleanly.
