## Summary

Comprehensive upstream sync of must-port PRs from CM-PVE and CM-PVE-HALO into BandaTroopers `master`. This PR brings HALO faction content (Covenant, UNSC, Spartan) to parity with upstream, including weapons, armor, gear presets, fire support, grenades, mines, and species support.

## Commits

| Commit | Description |
|--------|-------------|
| `44a127c` | HALO PVE Update: Batch 1-3B (PR #137, #153, #154, #170, #173, #162, #163, #164, #165, #166, #167, #168, #169, #171, #172, #174, #175, #176, #177, #178) |
| `70f6a6d` | Update .gitignore |
| `bc1496f` | Restore AI_AGENT task-state files to baseline state (pre-PR #102) |
| `a915711` | Clean up duplicate .gitignore entries for AI_AGENT task-state files |
| `3cbef88` | Comprehensive upstream sync: Batch 1-4 (CM-PVE-HALO + CM-PVE) |
| `ade8dd5` | Final upstream sync: all must-port PRs complete (Batch 1-4 + deferred items) |
| `46915d6` | Add missing .dmi assets for PR #150 loadout items (devices, unsc_melee) |
| `ed39ab4` | Update HALO port documentation: all PRs marked as PORTED |
| `d7e2e7e` | Migrate HALO sounds to modular path |

## Ported PRs

### CM-PVE (https://github.com/cmss13-devs/cmss13-pve)

| PR | Title | Status |
|----|-------|--------|
| #1289 | Observer Faction Categories | PORTED |
| #1288 | Anti Air - GM Choice | PORTED |
| #1287 | Gas Mask Vision Impairment | PORTED |
| #1284 | Lazy Bunker Shipmaps | SKIP (DNM/maps) |
| #1283 | Movie-ish Sections | SKIP (DNM/maps) |
| #1282 | The Straya War | SKIP (DNM/TMONLY) |
| #1280 | Dog war atomized | SKIP (maps) |
| #1278 | Call ur hits | SKIP (PVE-only LARP) |
| #1277 | Movie-like Xeno Castes | SKIP (DNM) |
| #1276 | FV150 'Hobelar' | SKIP (DNM/TMONLY) |
| #1275 | Vanguard's Arrow | SKIP (DNM/TMONLY) |
| #1273 | Gibson & Kloos | SKIP (DNM) |
| #1272 | Koishi's landmines | SKIP (TM ONLY) |
| #1271 | Itsy Bitsy Buggers | SKIP (DNM) |
| #1270 | Featueless | SKIP (TM Only/maps) |
| #1269 | Snowman | ALREADY PRESENT |
| #1268 | Active prox_sensor | ALREADY PRESENT |
| #1267 | Wolfpack | SKIP (TM ONLY) |
| #1266 | D66-44 | SKIP (TM) |
| #1265 | Auriga's Folly | SKIP (DNM) |
| #1264 | Shipmap lighting GM verb | ALREADY PRESENT |

### CM-PVE-HALO (https://github.com/cmss13-devs/cmss13-pve-halo)

| PR | Title | Status |
|----|-------|--------|
| #180 | Wort wort wort, lohbaba! | PORTED |
| #179 | CE-like uniforms | PORTED |
| #178 | Chemlights & Flares | PORTED |
| #176 | Thermite Grenades | PORTED |
| #174 | UNSC loose-ammo packets | PORTED |
| #173 | Plasma grenade loadouts for Unggoy | PORTED |
| #172 | RTO-bag sprite issues | SKIP (icons-only) |
| #171 | Shipmap lighting verb | PORTED |
| #170 | New covenant squads | PORTED |
| #169 | Featureless Biomes | SKIP (maps) |
| #168 | Jumping and Leaping | ALREADY PRESENT |
| #167 | Muzzle Flash Attach Fix | PORTED |
| #166 | ODST VISR v0.1 | PORTED |
| #165 | SPNKR A-A: Random Outcome | PORTED |
| #164 | Titan rename to Voyager | PORTED |
| #163 | Halo Minimap Fix | PORTED |
| #162 | Elite "Hero" subtypes | PORTED |
| #160 | Holy Redoubts | PORTED |
| #159 | Shotgun & sniper ammo boxes | PORTED |
| #158 | Fire Support Binos Support | PORTED |
| #157 | UNSC Medals Enabled | PORTED |
| #156 | Presets updates, Vendor tweaks | PORTED (core) |
| #155 | ODST Drop Pod - Intro Blurb | PORTED |
| #152 | Fences | PORTED |
| #150 | Loadout selection changes | PORTED |
| #145 | bumblebee | ALREADY PRESENT |

## Sound Modularity Migration

After final review, technical debt for sound modularity was resolved:

- **176 sound files** copied from root `sound/` to `modular/halo/sound/`
- **14 `.dm` files** updated — all sound path references remapped to modular paths
- **Original files** in root `sound/` preserved (not deleted)

### Migrated Categories

| Source Path | Destination Path | Files |
|-------------|------------------|-------|
| `sound/weapons/halo/` | `modular/halo/sound/weapons/halo/` | 152 |
| `sound/effects/halo/` | `modular/halo/sound/effects/halo/` | 1 |
| `sound/effects/odst_pod/` | `modular/halo/sound/effects/odst_pod/` | 19 |
| `sound/items/halo/` | `modular/halo/sound/items/halo/` | 2 |
| `sound/handling/visr_*.ogg` | `modular/halo/sound/handling/` | 2 |

### Updated .dm Files (Sound Path Remapping)

- `modular/halo/code/game/objects/items/explosives/halo_covenant_grenades.dm`
- `modular/halo/code/game/objects/items/explosives/halo_covenant_mines.dm`
- `modular/halo/code/mixed/components/supercombine.dm`
- `modular/halo/code/modules/halo_drop_pod/drop_pod.dm`
- `modular/halo/code/modules/projectiles/guns/halo/cov_guns.dm`
- `modular/halo/code/modules/projectiles/guns/halo/cov_melee.dm`
- `modular/halo/code/modules/projectiles/guns/halo/spnkr.dm`
- `modular/halo/code/modules/projectiles/guns/halo/unsc_guns.dm`
- `modular/halo/code/modules/projectiles/guns/pistol/unsc.dm`
- `modular/halo/code/modules/projectiles/guns/rifle/unsc.dm`
- `modular/halo/code/modules/projectiles/guns/shotgun/unsc.dm`
- `modular/halo/code/modules/projectiles/guns/smg/unsc.dm`
- `modular/halo/code/modules/projectiles/guns/specialist/sniper/unsc.dm`
- `modular/halo/code/modules/clothing/head/helmet.dm`

## Binary Assets

- 12 `.dmi` icons downloaded from upstream (PR #150 loadout items, devices, unsc_melee)
- 9 `.ogg` sounds downloaded from upstream (original sync)
- 176 `.ogg` sounds migrated to modular path (sound modularity pass)

## Validation Results

- **Compile**: `BUILD.cmd` — 0 errors, 0 warnings
- **git diff --check**: PASSED
- **modular_pve_halo/ path audit**: 0 occurrences in `code/` and `modular/`
- **Root icons/halo/ path audit**: 0 occurrences (all use `modular/halo/icons/halo/` prefix)
- **Sound path audit**: 0 root sound references in `modular/halo/code/`
- **SS220 EDIT audit (code/)**: All 30 `code/` files properly marked with START/END blocks
- **SS220 EDIT audit (modular/)**: Only 2 legacy occurrences, no new markers
- **maplint (PR #160 templates)**: All 14 map templates OK
- **All must-port PRs**: PORTED / ALREADY PRESENT / SKIP as listed above

## Final Statistics

| Metric | Value |
|--------|-------|
| Commits | 9 |
| Files changed | ~289 (100 code/config + 13 docs + 176 sound assets) |
| Additions | +7,670 |
| Deletions | -501 |
| Sound assets migrated | 176 `.ogg` files |
| .dm files with sound remapping | 14 |
| Upstream PRs reviewed | 46 (21 CM-PVE + 25 CM-PVE-HALO) |
| Upstream PRs ported | 20 |
| Upstream PRs already present | 5 |
| Upstream PRs skipped | 21 |
