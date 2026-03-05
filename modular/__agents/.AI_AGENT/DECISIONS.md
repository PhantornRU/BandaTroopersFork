# DECISIONS

## D-001: RU master is canonical for GroundSide inventory
- Missing maps were identified by RU master map inventory and filtered to GroundSide scope only.

## D-002: Source-canonical map paths use code-side compatibility types
- Added:
  - `/obj/item/storage/backpack/commando`
  - `/obj/item/clothing/head/beret/royal_marine`
  - `/obj/item/ammo_magazine/rifle/nsg23/extended`
- Reason: these paths are valid source references, not local corruption.

## D-003: Merge-corruption tokens are fixed map-side
- Broken paths/tokens in `Otogi`, `BigBlue`, `Onyx` were repaired directly in DMM content.
- Reason: these were local merge defects and must not become permanent aliases.

## D-004: Telecomms switch case uses explicit constants
- Replaced list-macro case with `FACTION_CANC, FACTION_CANC_DOGWAR` in faction `switch`.
- Reason: resolves DM `OD0500 Expected a constant`.

## D-005: DMI overflow strategy is split + repoint
- New states were moved out of overloaded base atlases to dedicated split files.
- Repoint done with explicit `item_icons`/wear-slot routing.

## D-006: Imported GroundSide maps must be normalized for repo contracts
- Imported maps were converted/sanitized to satisfy current maplint and mapmerge2 expectations.
- Support subtype additions were intentionally minimal integration points.

## D-007: Shipmap scope remained closed
- No RU shipmap ports were included.
- Ship-side map edits were limited to strict compile/maplint stabilization.

## D-008: Module-path maplint invocation workaround is accepted in this environment
- `tools/bootstrap/python -m tools.maplint.source --github` fails due module path resolution.
- Equivalent validated invocation:
  - `tools/bootstrap/python -c "import sys, runpy; sys.path.insert(0, '.'); runpy.run_module('tools.maplint.source', run_name='__main__')" --github`
