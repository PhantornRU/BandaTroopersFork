# DECISIONS

## D-001: Keep the persistence logic HALO-local
- Decision: implement the no-gun sword persistence check in HALO Sangheili helper/action code.
- Why: this is a HALO Sangheili behavior issue and does not justify widening shared upstream human AI logic.

## D-002: Fix the actual render bug, not the earlier assumption
- Decision: fix Sangheili sword visibility through a HALO-local hand-overlay override on the sword item.
- Why: investigation showed the hand DMI states exist, but Sangheili species offset handling clips 64x64 inhand overlays during runtime rendering.

## D-003: Preserve mixed ranged fallback behavior
- Decision: mixed Sangheili still holster the sword when they truly can return to a usable firearm.
- Why: only no-fallback terminal-sword cases should stop deactivating the blade.
